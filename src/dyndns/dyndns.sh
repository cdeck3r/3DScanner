#!/bin/bash
set -e

#
# Dynamic DNS 
# It enables the end-user to retrieve the scanner's UI IP address
#

# Params: none

# Exit codes
# 1 - if precond not satisfied
# 2 - if other things break

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
LOGFILE="${SCRIPT_DIR}/../register_3DScanner/nweb.log"
#LOGFILE="${SCRIPT_DIR}/nweb.log"
INDEX_HTML="${SCRIPT_DIR}/index.html"
SETUP_SH="${SCRIPT_DIR}/setup.sh"

#####################################################
# Include Helper functions
#####################################################

# shellcheck disable=SC1090
source "${SCRIPT_DIR}/funcs.sh"
assert_on_pc

#####################################################
# Main program
#####################################################

# test for webserver serving the index.html
[[ -f "${SETUP_SH}" ]] || { log_echo "ERROR" "Setup file not found: ${SETUP_SH}"; exit 1; }
PORT=$(grep "PORT=" "${SETUP_SH}" | cut -d'=' -f2)
pgrep -f "nweb ${PORT}" > /dev/null || { 
    log_echo "ERROR" "The webserver does not run. Please re-run setup."  
    exit 1
}

# test for webserver log
[[ -f "${LOGFILE}" ]] || {
    log_echo "ERROR" "Webserver logfile does not exist: ${LOGFILE}"
    exit 1
}
log_echo "INFO" "Extract IP address from logfile: ${LOGFILE}"

# extract IP address and time
SCANNER_IP=$(tail -n 1 "${LOGFILE}" | cut -d'=' -f2 | cut -d'%' -f1)
[[ -z "${SCANNER_IP}" ]] || log_echo "INFO" "Found scanner IP: ${SCANNER_IP}" 
LOGFILE_MTIME_SEC=$(stat -c %Y "${LOGFILE}")
LOGFILE_MTIME_DATE=$(date -d@"${LOGFILE_MTIME_SEC}" +"%Y-%m-%d %T %Z")
[[ -z "${LOGFILE_MTIME_DATE}" ]] || log_echo "INFO" "Last modification time: ${LOGFILE_MTIME_DATE}"


# write index.html
cat <<EOF >"${INDEX_HTML}"
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="refresh" content="10; url=http://$SCANNER_IP/ui">
</head>
<body>

<h1>3DScanner Dynamic DNS</h1>

<p>
<b>Last update:</b> $LOGFILE_MTIME_DATE
</p>

<!-- 
generated by table generator
https://www.tablesgenerator.com/html_tables
-->
<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;}
.tg td{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
  overflow:hidden;padding:10px 5px;word-break:normal;}
.tg th{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
  font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
.tg .tg-0pky{border-color:inherit;text-align:left;vertical-align:top}
@media screen and (max-width: 767px) {.tg {width: auto !important;}.tg col {width: auto !important;}.tg-wrap {overflow-x: auto;-webkit-overflow-scrolling: touch;}}</style>
<div class="tg-wrap"><table class="tg">
<tbody>
  <tr>
    <td class="tg-0pky">User interface</td>
    <td class="tg-0pky"><a href="http://$SCANNER_IP/ui">http://$SCANNER_IP/ui</a></td>
  </tr>
  <tr>
    <td class="tg-0pky">Image files</td>
    <td class="tg-0pky"><a href="http://$SCANNER_IP/">http://$SCANNER_IP/</a></td>
  </tr>
</tbody>
</table></div>


<br><br>
Project on Github: <a href="https://github.com/cdeck3r/3DScanner">https://github.com/cdeck3r/3DScanner</a>

</body>
</html>

EOF

chmod 644 "${INDEX_HTML}"

[[ -f "${INDEX_HTML}" ]] || {
    log_echo "ERROR" "File was not created: ${INDEX_HTML}"
    exit 2
}
log_echo "INFO" "File was successfully created: ${INDEX_HTML}"

exit 0
