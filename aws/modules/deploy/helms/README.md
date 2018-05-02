GPII Helm Charts
================

This is the place where the GPII Helm Charts live. The structure is pretty
basic:

- A directory per Helm Chart
- A variable file that will override the default variables of the chart with the naming (Helm Char Name)-custom-values.erb

With this approach the original Helm Chart doesn't needs any modification, as
all the variables will be set in the template file. This makes easy to use third
party Helm Charts.

Custom values file may also contain the following structure to set name and namespace values that will be passed to helm:

chart-metadata:
  name: install_name
  namespace: install_namespace
