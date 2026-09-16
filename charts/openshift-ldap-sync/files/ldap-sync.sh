#!/bin/bash
#
# Resolves the LDAP connection settings from the cluster wide OAuth resource
# and runs "oc adm groups sync" with the generated LDAPSyncConfig.
#
# The identity provider is looked up by name in spec.identityProviders. Its URL
# follows RFC 4516 and is split into the parts the LDAPSyncConfig expects:
#
#   ldaps://host:636/dc=foo,dc=bar,dc=de?sAMAccountName?sub?(objectClass=user)
#   \_____________/  \_________________/ \____________/ \_/ \_______________/
#         url               baseDN          attribute   scope     filter
#
# Everything the chart configures is handed over through the environment, see
# the ldap-env config map. Only the settings the identity provider genuinely
# does not carry have a fallback here, and only for the case that its URL
# leaves the respective part out.
#
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-/etc/config}"
WORKDIR="${WORKDIR:-/tmp/ldap-sync}"
SYNC_CONFIG="${WORKDIR}/ldap-group-sync.yaml"

mkdir -p "${WORKDIR}"

log() {
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*"
}

fail() {
  log "ERROR: $*" >&2
  exit 1
}

# Reads a single field of the LDAP identity provider from the OAuth resource.
idp_field() {
  oc get oauth "${OAUTH_NAME}" \
    -o jsonpath="{.spec.identityProviders[?(@.name==\"${IDP_NAME}\")]${1}}"
}

# Decodes percent escapes as used in LDAP URLs (RFC 4516).
urldecode() {
  local value="${1//+/ }"
  printf '%b' "${value//%/\\x}"
}

for var in IDP_NAME OAUTH_NAME CONFIG_NAMESPACE SYNC_MODE PAGE_SIZE \
           GROUP_UID_ATTRIBUTE GROUP_NAME_ATTRIBUTES GROUP_MEMBERSHIP_ATTRIBUTES; do
  [ -n "${!var:-}" ] || fail "${var} is not set"
done

SYNC_LIST_FILE="${SYNC_LIST_FILE:-${CONFIG_DIR}/${SYNC_MODE}.txt}"
[ -f "${SYNC_LIST_FILE}" ] || fail "sync list ${SYNC_LIST_FILE} does not exist"

log "reading identity provider '${IDP_NAME}' from oauth/${OAUTH_NAME}"

IDP_TYPE="$(idp_field '.type')"
[ -n "${IDP_TYPE}" ] || fail "identity provider '${IDP_NAME}' not found in oauth/${OAUTH_NAME}"
[ "${IDP_TYPE}" = "LDAP" ] || fail "identity provider '${IDP_NAME}' is of type '${IDP_TYPE}', expected 'LDAP'"

IDP_URL="$(idp_field '.ldap.url')"
[ -n "${IDP_URL}" ] || fail "identity provider '${IDP_NAME}' has no ldap.url"

IDP_BIND_DN="$(idp_field '.ldap.bindDN')"
IDP_INSECURE="$(idp_field '.ldap.insecure')"
IDP_BIND_PASSWORD_SECRET="$(idp_field '.ldap.bindPassword.name')"
IDP_CA_CONFIGMAP="$(idp_field '.ldap.ca.name')"

SCHEME="${IDP_URL%%://*}"
REMAINDER="${IDP_URL#*://}"
HOSTPORT="${REMAINDER%%/*}"

if [ "${REMAINDER}" = "${HOSTPORT}" ]; then
  QUERY=""
else
  QUERY="${REMAINDER#*/}"
fi

IFS='?' read -r URL_BASE_DN URL_ATTRIBUTE URL_SCOPE URL_FILTER <<< "${QUERY}"

URL_BASE_DN="$(urldecode "${URL_BASE_DN}")"
URL_ATTRIBUTE="$(urldecode "${URL_ATTRIBUTE}")"
URL_SCOPE="$(urldecode "${URL_SCOPE}")"
URL_FILTER="$(urldecode "${URL_FILTER}")"

LDAP_URL="${SCHEME}://${HOSTPORT}"
INSECURE="${IDP_INSECURE:-false}"

# A configured value wins over the identity provider, which in turn wins over
# the fallback for a URL that does not carry the respective part.
BIND_DN="${BIND_DN:-${IDP_BIND_DN}}"
GROUPS_BASE_DN="${GROUPS_BASE_DN:-${URL_BASE_DN}}"
USERS_BASE_DN="${USERS_BASE_DN:-${URL_BASE_DN}}"
LDAP_SCOPE="${LDAP_SCOPE:-${URL_SCOPE:-sub}}"
USER_NAME_ATTRIBUTES="${USER_NAME_ATTRIBUTES:-${URL_ATTRIBUTE:-sAMAccountName}}"
USERS_FILTER="${USERS_FILTER:-${URL_FILTER:-(objectclass=person)}}"

[ -n "${GROUPS_BASE_DN}" ] || fail "no base DN in ldap.url and no params.groupsBaseDN configured"
[ -n "${USERS_BASE_DN}" ] || fail "no base DN in ldap.url and no params.usersBaseDN configured"

# Bind password: either handed over by the chart or extracted from the secret
# the identity provider references.
BIND_PASSWORD_FILE="${BIND_PASSWORD_FILE:-}"
if [ -z "${BIND_PASSWORD_FILE}" ] && [ -n "${IDP_BIND_PASSWORD_SECRET}" ]; then
  log "extracting bind password from secret/${IDP_BIND_PASSWORD_SECRET} in ${CONFIG_NAMESPACE}"
  oc extract "secret/${IDP_BIND_PASSWORD_SECRET}" \
    --namespace "${CONFIG_NAMESPACE}" \
    --keys=bindPassword \
    --to="${WORKDIR}" \
    --confirm >/dev/null
  BIND_PASSWORD_FILE="${WORKDIR}/bindPassword"
fi

# CA bundle: either handed over by the chart or extracted from the config map
# the identity provider references.
CA_FILE="${CA_FILE:-}"
if [ -z "${CA_FILE}" ] && [ -n "${IDP_CA_CONFIGMAP}" ]; then
  log "extracting CA bundle from configmap/${IDP_CA_CONFIGMAP} in ${CONFIG_NAMESPACE}"
  oc extract "configmap/${IDP_CA_CONFIGMAP}" \
    --namespace "${CONFIG_NAMESPACE}" \
    --keys=ca.crt \
    --to="${WORKDIR}" \
    --confirm >/dev/null
  CA_FILE="${WORKDIR}/ca.crt"
fi

log "url=${LDAP_URL} insecure=${INSECURE} bindDN=${BIND_DN:-<anonymous>}"
log "groupsBaseDN=${GROUPS_BASE_DN} usersBaseDN=${USERS_BASE_DN} scope=${LDAP_SCOPE}"

{
  echo "kind: LDAPSyncConfig"
  echo "apiVersion: v1"
  echo "url: ${LDAP_URL}"
  echo "insecure: ${INSECURE}"
  [ -z "${CA_FILE}" ] || echo "ca: ${CA_FILE}"
  echo "bindDN: \"${BIND_DN}\""
  if [ -n "${BIND_PASSWORD_FILE}" ]; then
    echo "bindPassword:"
    echo "  file: \"${BIND_PASSWORD_FILE}\""
  fi
  echo "augmentedActiveDirectory:"
  echo "  groupsQuery:"
  echo "    baseDN: \"${GROUPS_BASE_DN}\""
  echo "    scope: ${LDAP_SCOPE}"
  echo "    derefAliases: never"
  echo "    pageSize: ${PAGE_SIZE}"
  [ -z "${GROUPS_FILTER:-}" ] || echo "    filter: \"${GROUPS_FILTER}\""
  echo "  groupUIDAttribute: ${GROUP_UID_ATTRIBUTE}"
  echo "  groupNameAttributes: [ ${GROUP_NAME_ATTRIBUTES} ]"
  echo "  usersQuery:"
  echo "    baseDN: \"${USERS_BASE_DN}\""
  echo "    scope: ${LDAP_SCOPE}"
  echo "    derefAliases: never"
  echo "    filter: \"${USERS_FILTER}\""
  echo "    pageSize: ${PAGE_SIZE}"
  echo "  userNameAttributes: [ ${USER_NAME_ATTRIBUTES} ]"
  echo "  groupMembershipAttributes: [ ${GROUP_MEMBERSHIP_ATTRIBUTES} ]"
} > "${SYNC_CONFIG}"

log "generated sync config:"
sed -e 's/^/  /' "${SYNC_CONFIG}"

exec oc adm groups sync \
  --sync-config="${SYNC_CONFIG}" \
  "--${SYNC_MODE}=${SYNC_LIST_FILE}" \
  --confirm
