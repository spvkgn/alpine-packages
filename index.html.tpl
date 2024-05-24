<!DOCTYPE html>
<!-- INDEX_TEMPLATE -->
<html lang="en">
  <head>
    <title>{{ .title }}</title>
    <link rel="stylesheet" href="{{ .style }}" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="UTF-8">
  </head>
  <body class="c">
    <h1>Index {{ with .dir }}of {{ . }}{{ end }}</h1>
    <hr />
    {{- if .add_top_level }}
    <div class="row">
      <div class="12 col"><a href="../">../</a></div>
    </div>
    {{- end }}
    {{- $files := .files -}}
    {{- range (keys $files | sortAlpha) }}
    {{- $file := get $files . }}
    <div class="row">
      <div class="7 col"><a href="{{ . }}">{{ . }}</a></div>
      <div class="3 col">
        <time datetime="{{ get $file "created_at" }}">
          <script>
            {
              let date = new Date(Date.parse("{{ get $file "created_at" }}"));
              document.write(date.toLocaleString());
            }
          </script>
        </time>
      </div>
      <div class="2 col">
        {{- if gt (get $file "size") 0 }}
        {{ get $file "size" | fileSize }}
        {{- end }}
      </div>
    </div>
    {{- end }}
    <hr />
  </body>
</html>
