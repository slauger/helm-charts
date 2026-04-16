{{/*
Shared VirtualMachine spec, used by both VirtualMachine and VirtualMachinePool templates.
*/}}
{{- define "library.vmSpec" -}}
runStrategy: {{ .Values.runStrategy }}
{{- if .Values.instancetype }}
instancetype:
  name: {{ .Values.instancetype.name }}
  kind: {{ .Values.instancetype.kind | default "VirtualMachineClusterInstancetype" }}
{{- end }}
{{- if .Values.preference }}
preference:
  name: {{ .Values.preference.name }}
  kind: {{ .Values.preference.kind | default "VirtualMachineClusterPreference" }}
{{- end }}
{{- if .Values.dataVolumeTemplates }}
dataVolumeTemplates:
  {{- toYaml .Values.dataVolumeTemplates | nindent 2 }}
{{- end }}
template:
  metadata:
    labels:
      {{- include "library.selectorLabels" . | nindent 6 }}
      {{- with .Values.labels }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    {{- with .Values.annotations }}
    annotations:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  spec:
    domain:
      {{- if not .Values.instancetype }}
      {{- with .Values.domain.resources }}
      resources:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.domain.cpu }}
      cpu:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- end }}
      {{- with .Values.domain.machine }}
      machine:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.domain.firmware }}
      firmware:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.domain.features }}
      features:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      devices:
        {{- if or .Values.domain.devices.disks .Values.cloudInit.enabled }}
        disks:
          {{- with .Values.domain.devices.disks }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
          {{- if .Values.cloudInit.enabled }}
          - name: cloudinitdisk
            disk:
              bus: virtio
          {{- end }}
        {{- end }}
        {{- with .Values.domain.devices.interfaces }}
        interfaces:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- if .Values.domain.devices.rng }}
        rng: {}
        {{- end }}
    {{- if or .Values.volumes .Values.cloudInit.enabled }}
    volumes:
      {{- with .Values.volumes }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
      {{- if .Values.cloudInit.enabled }}
      - name: cloudinitdisk
        {{- if eq .Values.cloudInit.type "configDrive" }}
        cloudInitConfigDrive:
        {{- else }}
        cloudInitNoCloud:
        {{- end }}
          {{- if .Values.cloudInit.userData }}
          userData: |
            {{- .Values.cloudInit.userData | nindent 12 }}
          {{- end }}
          {{- if .Values.cloudInit.networkData }}
          networkData: |
            {{- .Values.cloudInit.networkData | nindent 12 }}
          {{- end }}
      {{- end }}
    {{- end }}
    {{- with .Values.networks }}
    networks:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.accessCredentials }}
    accessCredentials:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.evictionStrategy }}
    evictionStrategy: {{ . }}
    {{- end }}
    {{- with .Values.terminationGracePeriodSeconds }}
    terminationGracePeriodSeconds: {{ . }}
    {{- end }}
    {{- with .Values.nodeSelector }}
    nodeSelector:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.tolerations }}
    tolerations:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.affinity }}
    affinity:
      {{- toYaml . | nindent 6 }}
    {{- end }}
{{- end }}
