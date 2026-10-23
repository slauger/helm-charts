{{- define "lab-vm.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "lab-vm.hostname" -}}
{{- .Values.hostname | default (include "lab-vm.fullname" .) -}}
{{- end -}}

{{- define "lab-vm.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "lab-vm.networkName" -}}
{{- .Values.lan.networkName | default (printf "%s-lan" (include "lab-vm.fullname" .)) -}}
{{- end -}}

{{/* Address without prefix length, for DNS */}}
{{- define "lab-vm.lanIP" -}}
{{- (split "/" .Values.lan.address)._0 -}}
{{- end -}}

{{- define "lab-vm.userData" -}}
{{- $base := dict
  "hostname" (include "lab-vm.hostname" .)
  "fqdn" (.Values.dns.hostname | default (include "lab-vm.hostname" .))
  "disable_root" false
  "ssh_pwauth" false
  "package_update" true
  "packages" .Values.cloudInit.packages
  "users" (list (dict "name" "root" "lock_passwd" true "ssh_authorized_keys" .Values.ssh.authorizedKeys))
  "write_files" (list (dict "path" "/etc/ssh/sshd_config.d/10-root-key-only.conf" "content" "PermitRootLogin prohibit-password\nPasswordAuthentication no\n"))
  "runcmd" (list "systemctl enable --now qemu-guest-agent" "systemctl reload ssh || systemctl reload sshd")
-}}
{{- $merged := mergeOverwrite $base (deepCopy .Values.cloudInit.extraUserData) -}}
#cloud-config
{{ toYaml $merged }}
{{- end -}}

{{- define "lab-vm.networkData" -}}
version: 2
ethernets:
  pod:
    match:
      macaddress: {{ .Values.podNetwork.mac | quote }}
    set-name: pod0
    dhcp4: true
    dhcp4-overrides:
      use-routes: false
      use-dns: false
    routes:
      {{- range .Values.podNetwork.clusterCIDRs }}
      - to: {{ . }}
        via: {{ $.Values.podNetwork.gateway }}
      {{- end }}
  {{- if .Values.lan.enabled }}
  lan:
    match:
      macaddress: {{ .Values.lan.mac | quote }}
    set-name: lan0
    {{- if .Values.lan.address }}
    addresses:
      - {{ .Values.lan.address }}
    {{- with .Values.lan.gateway }}
    routes:
      - to: default
        via: {{ . }}
    {{- end }}
    {{- if or .Values.lan.nameservers .Values.lan.searchDomains }}
    nameservers:
      {{- with .Values.lan.nameservers }}
      addresses: {{ toJson . }}
      {{- end }}
      {{- with .Values.lan.searchDomains }}
      search: {{ toJson . }}
      {{- end }}
    {{- end }}
    {{- else }}
    dhcp4: true
    {{- end }}
  {{- end }}
{{- end -}}
