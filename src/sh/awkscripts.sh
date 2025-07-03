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
