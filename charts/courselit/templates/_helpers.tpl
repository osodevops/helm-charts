{{/*
Expand the name of the chart.
*/}}
{{- define "courselit.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "courselit.fullname" -}}
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
{{- define "courselit.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "courselit.labels" -}}
helm.sh/chart: {{ include "courselit.chart" . }}
{{ include "courselit.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "courselit.selectorLabels" -}}
app.kubernetes.io/name: {{ include "courselit.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
App component labels
*/}}
{{- define "courselit.app.labels" -}}
{{ include "courselit.labels" . }}
app.kubernetes.io/component: app
{{- end }}

{{/*
App selector labels
*/}}
{{- define "courselit.app.selectorLabels" -}}
{{ include "courselit.selectorLabels" . }}
app.kubernetes.io/component: app
{{- end }}

{{/*
Queue component labels
*/}}
{{- define "courselit.queue.labels" -}}
{{ include "courselit.labels" . }}
app.kubernetes.io/component: queue
{{- end }}

{{/*
Queue selector labels
*/}}
{{- define "courselit.queue.selectorLabels" -}}
{{ include "courselit.selectorLabels" . }}
app.kubernetes.io/component: queue
{{- end }}

{{/*
MediaLit component labels
*/}}
{{- define "courselit.medialit.labels" -}}
{{ include "courselit.labels" . }}
app.kubernetes.io/component: medialit
{{- end }}

{{/*
MediaLit selector labels
*/}}
{{- define "courselit.medialit.selectorLabels" -}}
{{ include "courselit.selectorLabels" . }}
app.kubernetes.io/component: medialit
{{- end }}

{{/*
App image
*/}}
{{- define "courselit.app.image" -}}
{{- printf "%s:%s" .Values.app.image.repository (.Values.app.image.tag | default .Chart.AppVersion) }}
{{- end }}

{{/*
Queue image
*/}}
{{- define "courselit.queue.image" -}}
{{- printf "%s:%s" .Values.queue.image.repository (.Values.queue.image.tag | default .Chart.AppVersion) }}
{{- end }}

{{/*
MediaLit image
*/}}
{{- define "courselit.medialit.image" -}}
{{- printf "%s:%s" .Values.medialit.image.repository (.Values.medialit.image.tag | default .Chart.AppVersion) }}
{{- end }}

{{/*
MediaLit ServiceAccount name
*/}}
{{- define "courselit.medialit.serviceAccountName" -}}
{{- if .Values.medialit.serviceAccount.create }}
{{- default (printf "%s-medialit" (include "courselit.fullname" .)) .Values.medialit.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.medialit.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
MongoDB connection string for app
*/}}
{{- define "courselit.mongodb.connectionString" -}}
{{- if .Values.mongodb.enabled }}
{{- $fullname := include "courselit.fullname" . }}
{{- $mongoHost := printf "%s-mongodb-svc.%s.svc.cluster.local" $fullname .Release.Namespace }}
{{- printf "mongodb://%s:PASSWORD@%s/courselit?authSource=admin" .Values.mongodb.auth.rootUsername $mongoHost }}
{{- else }}
{{- .Values.mongodb.external.connectionString }}
{{- end }}
{{- end }}

{{/*
MongoDB connection string for MediaLit
*/}}
{{- define "courselit.mongodb.medialitConnectionString" -}}
{{- if .Values.mongodb.enabled }}
{{- $fullname := include "courselit.fullname" . }}
{{- $mongoHost := printf "%s-mongodb-svc.%s.svc.cluster.local" $fullname .Release.Namespace }}
{{- printf "mongodb://%s:PASSWORD@%s/medialit?authSource=admin" .Values.mongodb.auth.rootUsername $mongoHost }}
{{- else }}
{{- .Values.mongodb.external.connectionString | replace "/courselit" "/medialit" }}
{{- end }}
{{- end }}

{{/*
Redis host for queue service
*/}}
{{- define "courselit.redis.host" -}}
{{- if .Values.redis.external.enabled }}
{{- .Values.redis.external.host }}
{{- else }}
{{- printf "%s-valkey-master" .Release.Name }}
{{- end }}
{{- end }}

{{/*
MongoDB wait initContainer
*/}}
{{- define "courselit.mongodb.initContainer" -}}
- name: wait-for-mongodb
  image: busybox:1.36
  command:
    - sh
    - -c
    - |
      echo "Waiting for MongoDB to be ready..."
      {{- if .Values.mongodb.enabled }}
      {{- $fullname := include "courselit.fullname" . }}
      MONGO_HOST="{{ printf "%s-mongodb-svc.%s.svc.cluster.local" $fullname .Release.Namespace }}"
      {{- else }}
      {{- $parts := regexSplit "mongodb://([^@]+@)?([^/]+)" .Values.mongodb.external.connectionString -1 }}
      {{- if gt (len $parts) 2 }}
      MONGO_HOST="{{ index $parts 2 | regexFind "[^:/]+" }}"
      {{- else }}
      MONGO_HOST="localhost"
      {{- end }}
      {{- end }}
      until nc -z -w2 $MONGO_HOST 27017; do
        echo "MongoDB not ready yet. Retrying in 2 seconds..."
        sleep 2
      done
      echo "MongoDB is ready!"
{{- end }}

{{/*
Redis wait initContainer
*/}}
{{- define "courselit.redis.initContainer" -}}
- name: wait-for-redis
  image: busybox:1.36
  command:
    - sh
    - -c
    - |
      echo "Waiting for Redis to be ready..."
      REDIS_HOST="{{ include "courselit.redis.host" . }}"
      REDIS_PORT="{{ .Values.redis.external.port | default 6379 }}"
      until nc -z -w2 $REDIS_HOST $REDIS_PORT; do
        echo "Redis not ready yet. Retrying in 2 seconds..."
        sleep 2
      done
      echo "Redis is ready!"
{{- end }}
