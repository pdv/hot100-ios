
csv_file=$(mktemp)
curl https://raw.githubusercontent.com/utdata/rwd-billboard-data/main/data-out/hot-100-current.csv -o ${csv_file}

sqlite3 hot100.db <<EOS
.mode csv 
.import ${csv_file} hot100
EOS

sqlite-utils transform hot100.db hot100 \
    --type current_week integer \
    --type last_week integer \
    --type peak_pos integer \
    --type wks_on_chart integer

