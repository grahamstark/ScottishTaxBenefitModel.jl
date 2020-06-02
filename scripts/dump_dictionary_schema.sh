#
# save the pg dictionaries schema
# on why "--inserts", see: https://stackoverflow.com/questions/20427689/psql-invalid-command-n-while-restore-sql
#
pg_dump msc -U postgres -n dictionaries --create --inserts > ~/tmp/dictionaries.sql
