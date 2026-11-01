# immich (not deployed)

The ApplicationSets for `immich` and `immich-prereq` are left out until #1910 is fixed:
chart 0.12 removed the bundled postgres subchart that `values-nas.yaml` still configures.
The values and the prereq PVC manifest are kept here as the starting point.
