{{- define "orderflow.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "orderflow.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "orderflow.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "orderflow.labels" -}}
app.kubernetes.io/name: {{ include "orderflow.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end }}

{{- define "orderflow.apiImage" -}}
{{- if and .Values.global.requireDigest (not .Values.api.image.digest) -}}
{{- fail "api.image.digest is required when global.requireDigest=true" -}}
{{- end -}}
{{- if .Values.api.image.digest -}}
{{ printf "%s@%s" .Values.api.image.repository .Values.api.image.digest }}
{{- else -}}
{{ printf "%s:%s" .Values.api.image.repository .Values.api.image.tag }}
{{- end -}}
{{- end }}

{{- define "orderflow.workerImage" -}}
{{- if and .Values.global.requireDigest (not .Values.worker.image.digest) -}}
{{- fail "worker.image.digest is required when global.requireDigest=true" -}}
{{- end -}}
{{- if .Values.worker.image.digest -}}
{{ printf "%s@%s" .Values.worker.image.repository .Values.worker.image.digest }}
{{- else -}}
{{ printf "%s:%s" .Values.worker.image.repository .Values.worker.image.tag }}
{{- end -}}
{{- end }}
