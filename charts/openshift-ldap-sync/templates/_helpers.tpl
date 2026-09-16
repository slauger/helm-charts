{{/*
Name of the service account used by the cronjob.
*/}}
{{- define "openshift-ldap-sync.serviceAccountName" -}}
{{- default .Release.Name .Values.serviceAccount.name -}}
{{- end -}}
