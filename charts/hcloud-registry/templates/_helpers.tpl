{{/*
Expand the name of the chart.
*/}}
{{- define "hcloud-registry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "hcloud-registry.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hcloud-registry.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hcloud-registry.labels" -}}
helm.sh/chart: {{ include "hcloud-registry.chart" . }}
{{ include "hcloud-registry.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hcloud-registry.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hcloud-registry.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "hcloud-registry.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hcloud-registry.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Registry image
*/}}
{{- define "hcloud-registry.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- if .Values.image.registry }}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository $tag }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}
{{- end }}

{{/*
Authentication is enabled when an htpasswd value or an existing Secret is given
*/}}
{{- define "hcloud-registry.authEnabled" -}}
{{- if or .Values.auth.existingSecret .Values.auth.htpasswd }}true{{- end }}
{{- end }}

{{/*
Secret and key holding the htpasswd file
*/}}
{{- define "hcloud-registry.authSecretName" -}}
{{- .Values.auth.existingSecret | default (printf "%s-auth" (include "hcloud-registry.fullname" .)) }}
{{- end }}

{{- define "hcloud-registry.authSecretKey" -}}
{{- if .Values.auth.existingSecret }}{{ .Values.auth.existingSecretKey | default "htpasswd" }}{{ else }}htpasswd{{ end }}
{{- end }}

{{/*
S3 credentials come from an existing Secret or from accessKey/secretKey
*/}}
{{- define "hcloud-registry.s3CredentialsEnabled" -}}
{{- if or .Values.storage.s3.existingSecret (and .Values.storage.s3.accessKey .Values.storage.s3.secretKey) }}true{{- end }}
{{- end }}

{{- define "hcloud-registry.s3SecretName" -}}
{{- .Values.storage.s3.existingSecret | default (printf "%s-s3" (include "hcloud-registry.fullname" .)) }}
{{- end }}

{{- define "hcloud-registry.s3AccessKeyKey" -}}
{{- if .Values.storage.s3.existingSecret }}{{ .Values.storage.s3.existingSecretAccessKeyKey | default "accessKey" }}{{ else }}accessKey{{ end }}
{{- end }}

{{- define "hcloud-registry.s3SecretKeyKey" -}}
{{- if .Values.storage.s3.existingSecret }}{{ .Values.storage.s3.existingSecretSecretKeyKey | default "secretKey" }}{{ else }}secretKey{{ end }}
{{- end }}
