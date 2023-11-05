#!/bin/bash -p

# EMBA - EMBEDDED LINUX ANALYZER
#
# Copyright 2020-2023 Siemens AG
# Copyright 2020-2023 Siemens Energy AG
#
# EMBA comes with ABSOLUTELY NO WARRANTY. This is free software, and you are
# welcome to redistribute it under the terms of the GNU General Public License.
# See LICENSE file for usage of this software.
#
# EMBA is licensed under GPLv3
#
# Author(s): Michael Messner, Pascal Eckmann

# Description:  Searches for http and webserver (Apache, nginx, Lighttpd, etc.) related files and checks for php.ini.

S35_http_file_check()
{
  module_log_init "${FUNCNAME[0]}"
  module_title "Check HTTP files"
  pre_module_reporter "${FUNCNAME[0]}"

  export HTTP_COUNTER=0

  write_csv_log "type" "filename" "file"
  web_file_search
  http_file_search
  webserver_check
  php_check

  module_end_log "${FUNCNAME[0]}" "${HTTP_COUNTER}"
}

web_file_search()
{
  sub_module_title "Search web served files"

  local WEB_STUFF=()
  local WEB_FILE=""

  mapfile -t WEB_STUFF < <(find "${FIRMWARE_PATH}" -xdev -type f \( -iname "*.htm" -o -iname "*.html" -o -iname "*.cgi" \
    -o -iname "*.asp" -o -iname "*.php" -o -iname "*.xml" -o -iname "*.rg" \) -exec md5sum {} \; 2>/dev/null | sort -u -k1,1 | cut -d\  -f3)

  if [[ -v WEB_STUFF[@] ]] ; then
    print_output "[+] Found web related files:"
    for WEB_FILE in "${WEB_STUFF[@]}" ; do
      print_output "$(indent "$(print_path "${WEB_FILE}")")"
      write_csv_log "Web served files" "$(basename "${WEB_FILE}")" "${WEB_FILE}"
      ((HTTP_COUNTER+=1))
    done
  else
    print_output "[-] No web related files found"
  fi
}

http_file_search()
{
  sub_module_title "Search http files"

  local HTTP_STUFF=()
  local HTTP_FILE=""
  mapfile -t HTTP_STUFF < <(config_find "${CONFIG_DIR}""/http_files.cfg")

  if [[ "${HTTP_STUFF[0]-}" == "C_N_F" ]] ; then print_output "[!] Config not found"
  elif [[ "${#HTTP_STUFF[@]}" -ne 0 ]] ; then
    print_output "[+] Found http related files:"
    for HTTP_FILE in "${HTTP_STUFF[@]}" ; do
      print_output "$(indent "$(print_path "${HTTP_FILE}")")"
      write_csv_log "HTTP server files" "$(basename "${HTTP_FILE}")" "${HTTP_FILE}"
      ((HTTP_COUNTER+=1))
    done
  else
    print_output "[-] No http related files found"
  fi
}

webserver_check()
{
  sub_module_title "Check for apache or nginx related files"

  local APACHE_FILE_ARR=()
  local NGINX_FILE_ARR=()
  local LIGHTTP_FILE_ARR=()
  local CHEROKEE_FILE_ARR=()
  local HTTPD_FILE_ARR=()
  local LINE=""

  readarray -t APACHE_FILE_ARR < <( find "${FIRMWARE_PATH}" -xdev "${EXCL_FIND[@]}" -iname '*apache*' -exec md5sum {} \; 2>/dev/null | sort -u -k1,1 | cut -d\  -f3 )
  readarray -t NGINX_FILE_ARR < <( find "${FIRMWARE_PATH}" -xdev "${EXCL_FIND[@]}" -iname '*nginx*' -exec md5sum {} \; 2>/dev/null | sort -u -k1,1 | cut -d\  -f3 )
  readarray -t LIGHTTP_FILE_ARR < <( find "${FIRMWARE_PATH}" -xdev "${EXCL_FIND[@]}" -iname '*lighttp*' -exec md5sum {} \; 2>/dev/null | sort -u -k1,1 | cut -d\  -f3 )
  readarray -t CHEROKEE_FILE_ARR < <( find "${FIRMWARE_PATH}" -xdev "${EXCL_FIND[@]}" -iname '*cheroke*' -exec md5sum {} \; 2>/dev/null | sort -u -k1,1 | cut -d\  -f3 )
  readarray -t HTTPD_FILE_ARR < <( find "${FIRMWARE_PATH}" -xdev "${EXCL_FIND[@]}" -iname '*httpd*' -exec md5sum {} \; 2>/dev/null | sort -u -k1,1 | cut -d\  -f3 )

  if [[ ${#APACHE_FILE_ARR[@]} -gt 0 ]] ; then
    print_output "[+] Found Apache related files:"
    for LINE in "${APACHE_FILE_ARR[@]}" ; do
      print_output "$(indent "$(print_path "${LINE}")")"
      write_csv_log "Apache web server file" "$(basename "${LINE}")" "${LINE}"
      ((HTTP_COUNTER+=1))
    done
  else
    print_output "[-] No Apache related files found"
  fi

  if [[ ${#NGINX_FILE_ARR[@]} -gt 0 ]] ; then
    print_output "[+] Found nginx related files:"
    for LINE in "${NGINX_FILE_ARR[@]}" ; do
      print_output "$(indent "$(print_path "${LINE}")")"
      write_csv_log "Nginx web server file" "$(basename "${LINE}")" "${LINE}"
      ((HTTP_COUNTER+=1))
    done
  else
    print_output "[-] No nginx related files found"
  fi

  if [[ ${#LIGHTTP_FILE_ARR[@]} -gt 0 ]] ; then
    print_output "[+] Found Lighttpd related files:"
    for LINE in "${LIGHTTP_FILE_ARR[@]}" ; do
      print_output "$(indent "$(print_path "${LINE}")")"
      write_csv_log "Lighttpd web server file" "$(basename "${LINE}")" "${LINE}"
      ((HTTP_COUNTER+=1))
    done
  else
    print_output "[-] No Lighttpd related files found"
  fi

  if [[ ${#CHEROKEE_FILE_ARR[@]} -gt 0 ]] ; then
    print_output "[+] Found Cherokee related files:"
    for LINE in "${CHEROKEE_FILE_ARR[@]}" ; do
      print_output "$(indent "$(print_path "${LINE}")")"
      write_csv_log "Cherokee web server file" "$(basename "${LINE}")" "${LINE}"
      ((HTTP_COUNTER+=1))
    done
  else
    print_output "[-] No Cherokee related files found"
  fi

  if [[ ${#HTTPD_FILE_ARR[@]} -gt 0 ]] ; then
    print_output "[+] Found HTTPd related files:"
    for LINE in "${HTTPD_FILE_ARR[@]}" ; do
      print_output "$(indent "$(print_path "${LINE}")")"
      write_csv_log "HTTPd web server file" "$(basename "${LINE}")" "${LINE}"
      ((HTTP_COUNTER+=1))
    done
  else
    print_output "[-] No HTTPd related files found"
  fi
}

php_check()
{
  sub_module_title "Check for php.ini"
  local PHP_INI_ARR=()
  local PHP_INI_ENTRY=""

  readarray -t PHP_INI_ARR < <( find "${FIRMWARE_PATH}" -xdev "${EXCL_FIND[@]}" -iname '*php.ini' -exec md5sum {} \; 2>/dev/null | sort -u -k1,1 | cut -d\  -f3 )

  if [[ ${#PHP_INI_ARR[@]} -gt 0 ]] ; then
    print_output "[+] Found php.ini:"
    for PHP_INI_ENTRY in "${PHP_INI_ARR[@]}" ; do
      print_output "$(indent "$(print_path "${PHP_INI_ENTRY}")")"
      write_csv_log "php.ini file" "$(basename "${PHP_INI_ENTRY}")" "${PHP_INI_ENTRY}"
      ((HTTP_COUNTER+=1))
    done
  else
    print_output "[-] No php.ini found"
  fi
}
