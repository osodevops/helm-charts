{{/*
Expand the name of the chart.
*/}}
{{- define "kafka-connect.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kafka-connect.fullname" -}}
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
{{- define "kafka-connect.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kafka-connect.labels" -}}
helm.sh/chart: {{ include "kafka-connect.chart" . }}
{{ include "kafka-connect.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kafka-connect.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kafka-connect.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kafka-connect.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kafka-connect.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the config topic to use
*/}}
{{- define "kafka-connect.storageConfig" -}}
{{- $global := .global -}}
{{- $config := .config -}}
{{- $clustername := .clustername -}}
{{- $topic_prefix := (printf "%s-%s" $global.configTopicPrefix $clustername) -}}
{{- $topic_configs := $config.topics | default $global.topics }}
{{- range $topic, $topic_defaults := $global.topics }}
{{- $topic_config := index $topic_configs $topic | default $topic_defaults }}
{{ $topic }}.storage.replication.factor: {{ $topic_config.replicationFactor | default $topic_defaults.replicationFactor }}
{{ $topic }}.storage.topic: {{ $topic_config.topic | default (printf "%s-%s" $topic_prefix $topic) }}
{{- end }}
{{- end }}

