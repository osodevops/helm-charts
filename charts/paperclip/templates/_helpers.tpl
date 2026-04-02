{{/*
Expand the name of the chart.
*/}}
{{- define "paperclip.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "paperclip.fullname" -}}
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
{{- define "paperclip.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "paperclip.labels" -}}
helm.sh/chart: {{ include "paperclip.chart" . }}
{{ include "paperclip.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "paperclip.selectorLabels" -}}
app.kubernetes.io/name: {{ include "paperclip.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "paperclip.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "paperclip.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "paperclip.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end }}

{{/*
Return the name of the application secrets Secret
*/}}
{{- define "paperclip.secretName" -}}
{{- printf "%s-secrets" (include "paperclip.fullname" .) }}
{{- end }}

{{/*
Return the name of the database credentials Secret
*/}}
{{- define "paperclip.dbSecretName" -}}
{{- if and (not .Values.postgresql.enabled) .Values.postgresql.external.existingSecret }}
{{- .Values.postgresql.external.existingSecret }}
{{- else }}
{{- printf "%s-db" (include "paperclip.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Return the name of the main ConfigMap
*/}}
{{- define "paperclip.configMapName" -}}
{{- printf "%s-config" (include "paperclip.fullname" .) }}
{{- end }}

{{/*
Construct the DATABASE_URL from components.
Handles internal (subchart) vs external PostgreSQL and connectionPooling.
*/}}
{{- define "paperclip.databaseUrl" -}}
{{- if .Values.postgresql.enabled -}}
  {{- $host := printf "%s-postgresql" (include "paperclip.fullname" .) -}}
  {{- $port := "5432" -}}
  {{- $user := .Values.postgresql.auth.username -}}
  {{- $db := .Values.postgresql.auth.database -}}
  {{- printf "postgres://%s:$(DATABASE_PASSWORD)@%s:%s/%s" $user $host $port $db -}}
{{- else -}}
  {{- $host := .Values.postgresql.external.host -}}
  {{- $port := .Values.postgresql.external.port | toString -}}
  {{- $user := .Values.postgresql.external.username -}}
  {{- $db := .Values.postgresql.external.database -}}
  {{- $sslMode := .Values.postgresql.external.sslMode -}}
  {{- $base := printf "postgres://%s:$(DATABASE_PASSWORD)@%s:%s/%s?sslmode=%s" $user $host $port $db $sslMode -}}
  {{- if .Values.postgresql.external.connectionPooling -}}
    {{- printf "%s&prepare=false" $base -}}
  {{- else -}}
    {{- $base -}}
  {{- end -}}
{{- end -}}
{{- end }}
