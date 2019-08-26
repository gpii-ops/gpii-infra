{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "couchdb_prometheus_exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "couchdb_prometheus_exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a random string if the supplied key does not exist
*/}}
{{- define "couchdb_prometheus_exporter.defaultsecret" -}}
{{- if . -}}
{{- . | b64enc | quote -}}
{{- else -}}
{{- randAlphaNum 20 | b64enc | quote -}}
{{- end -}}
{{- end -}}
