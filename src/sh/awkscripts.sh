AWK_ALTERTODO=$(
  cat <<'EOF'
@@include awk/altertodo.awk
EOF
)
export AWK_ALTERTODO

AWK_EXPORT=$(
  cat <<'EOF'
@@include awk/export.awk
EOF
)
export AWK_EXPORT

AWK_GET=$(
  cat <<'EOF'
@@include awk/get.awk
EOF
)
export AWK_GET

AWK_LIST=$(
  cat <<'EOF'
  @@include awk/list.awk
EOF
)
export AWK_LIST

AWK_NEW=$(
  cat <<'EOF'
@@include awk/new.awk
EOF
)
export AWK_NEW

AWK_UPDATE=$(
  cat <<'EOF'
@@include awk/update.awk
EOF
)
export AWK_UPDATE

AWK_ATTACH=$(
  cat <<'EOF'
@@include awk/attach.awk
EOF
)
export AWK_ATTACH

AWK_ATTACHDD=$(
  cat <<'EOF'
@@include awk/attachdd.awk
EOF
)
export AWK_ATTACHDD

AWK_ATTACHLS=$(
  cat <<'EOF'
@@include awk/attachls.awk
EOF
)
export AWK_ATTACHLS

AWK_ATTACHRM=$(
  cat <<'EOF'
@@include awk/attachrm.awk
EOF
)
export AWK_ATTACHRM
