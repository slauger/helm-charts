{{- define "shelve.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "shelve.fullname" -}}
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

{{- define "shelve.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "shelve.selectorLabels" . }}
{{- end }}

{{- define "shelve.selectorLabels" -}}
app.kubernetes.io/name: {{ include "shelve.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Die Umgebung, die Backend und Init-Job teilen. Eine Abweichung zwischen beiden
     hiesse: der Job migriert eine andere Datenbank als die, die das Backend bedient. */}}
{{- define "shelve.backendEnv" -}}
- name: SHELVE_DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "shelve.fullname" . }}-db-app
      key: uri
- name: SHELVE_JWT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "shelve.fullname" . }}-secrets
      key: jwt-secret
- name: SHELVE_DEBUG
  value: {{ .Values.env.debug | quote }}
{{- if .Values.env.corsOrigins }}
- name: SHELVE_CORS_ORIGINS
  value: {{ .Values.env.corsOrigins | quote }}
{{- end }}
{{- if .Values.env.googleBooksApiKeySealed }}
- name: SHELVE_GOOGLE_BOOKS_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "shelve.fullname" . }}-google-books
      key: api-key
{{- end }}
{{- end }}
