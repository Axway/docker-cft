{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "transfer-cft.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "transfer-cft.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "transfer-cft.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account
*/}}
{{- define "transfer-cft.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "transfer-cft.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "transfer-cft.labels" -}}
helm.sh/chart: {{ include "transfer-cft.chart" . }}
{{ include "transfer-cft.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "transfer-cft.selectorLabels" -}}
app: {{ include "transfer-cft.name" . }}
release: {{ .Release.Name }}
chart: {{ include "transfer-cft.chart" . }}
app.kubernetes.io/name: {{ include "transfer-cft.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Define the cft-custom path to use
*/}}
{{- define "cft.custom_path" -}}
{{- range .Values.extraVolumeMounts -}}
{{- if (eq .name "cft-custom") -}}
{{ default .mountPath }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Define the cft-secrets path to use
*/}}
{{- define "cft.secrets_path" -}}
{{- range .Values.extraSecretMounts -}}
{{- if (eq .name "secret-files") -}}
{{ default .mountPath }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Define variables to direct access to ports for different protocols (from service.ports)
*/}}
{{- define "cft.ports.pesit" -}}
{{- range .Values.service.ports -}}
{{- if (eq .name "pesit") -}}
{{ default .port }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- define "cft.ports.pesitssl" -}}
{{- range .Values.service.ports -}}
{{- if (eq .name "pesitssl") -}}
{{ default .port }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- define "cft.ports.sftp" -}}
{{- range .Values.service.ports -}}
{{- if (eq .name "sftp") -}}
{{ default .port }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- define "cft.ports.copilot" -}}
{{- range .Values.service.ports -}}
{{- if (eq .name "copilot") -}}
{{ default .port }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- define "cft.ports.copilotcg" -}}
{{- range .Values.service.ports -}}
{{- if (eq .name "copilotcg") -}}
{{ default .port }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- define "cft.ports.restapi" -}}
{{- range .Values.service.ports -}}
{{- if (eq .name "restapi") -}}
{{ default .port }}
{{- end -}}
{{- end -}}
{{- end -}}
