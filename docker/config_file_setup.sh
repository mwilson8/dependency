#!/bin/sh

get_properties_config_field_name() {
	# Remove any leading whitespace
	trimmed="$(echo -e "${@}" | sed -e 's/^[[:space:]]*//')"

	# Skip comments or empty lines
	if [[ "${trimmed:0:1}" != "#" && "$trimmed" != "" ]]
	then
		# Return the field name before the '='
		echo $trimmed | cut -d = -f 1
	fi
}

get_environment_variable_name() {
	f_name="$@"

	# Remove the '-' from the first character if it exists (such as in parameters.config)
	if [[ ${f_name:0:1} == "-" ]]
	then
		f_name=${f_name:1}
	fi

	# Uppercase the fieldname
	ucase_fname=`echo $f_name | tr '[a-z]' '[A-Z]'`

	# Replace all '.' with '_'
	echo ${ucase_fname//./_}
}

for file in "$SERVICE_HOME"/etc/*; do

   	extension="${file##*.}"
   	filename=` echo ${file%.*} | rev | cut -d / -f 1 | rev`
	# If the file is a .properties or .config file
	if [[ "$extension" == properties || "$extension" == config ]]
	then
		# Add an empty line to the end in case it isn't there.
		echo "" >> $file

	    echo "Updating fields in $file"
		# Iterate through each line of the file.
		while read line; do
		  # Get the field
		  field_name=$(get_properties_config_field_name "$line")
		  if [[ "$field_name" != "" ]]
	  	  then
	  	  	# Transform the field name to the environment variable name
	  	  	ev_name=$(get_environment_variable_name "$field_name")

	  	  	# Get the value of the environment variable
            ev_value=$(eval "echo \"\$$ev_name\"")

	  	  	# If the value is set, sed it into the file.
	  	  	if [[ "$ev_value" != "" ]]
  	  		then
  	  			sed -i -E "s/^(-?$field_name=).*/\1$(echo "$ev_value" | sed -e 's/[\/&]/\\&/g')/" $file
  			fi
  	  	  fi
		done < "$file"
	# If "LOG_LEVEL" environment variable is set, 'sed' it into the logback.xml file.
	elif [[ "$filename.$extension" == logback.xml && "$LOG_LEVEL" != "" ]]
	then
	    echo "Setting Log Level to $LOG_LEVEL"
		sed -i "/<root.*>/,/<\/root>/s/level=\"\([^\"]*\)\"/level=\"$LOG_LEVEL\"/" $file
	fi
done

for file in $(echo $CONFIG_FILES | sed "s/,/ /g"); do
	# Add an empty line to the end in case it isn't there.
	echo "" >> $file

   	extension="${file##*.}"
   	filename=` echo ${file%.*} | rev | cut -d / -f 1 | rev`
	echo "Updating fields in $file"
	# Iterate through each line of the file.
	while read line; do
	  # Get the field
	  field_name=$(get_properties_config_field_name "$line")

	  if [[ "$field_name" != "" ]]
	  then
		# Transform the field name to the environment variable name
		ev_name=$(get_environment_variable_name "$field_name")

		# Get the value of the environment variable
		ev_value=$(eval "echo \"\$$ev_name\"")

		# If the value is set, sed it into the file.
		if [[ "$ev_value" != "" ]]
		then
			sed -i -E "s/^(-?$field_name=).*/\1$(echo "$ev_value" | sed -e 's/[\/&]/\\&/g')/" $file
		fi
	  fi
	done < "$file"
done

######################
# Whitelist handling #
######################

# Define field-separate for for-loop so it doesn't split on spaces.
IFS=$'\n'

# Add empty line in case there is no ending line feed.
if [[ "$ACL_WHITELIST_FILE" != "" ]]
then
	echo "" >> $ACL_WHITELIST_FILE

	for entry in $(echo $WHITELIST_ENTRIES | sed "s/[|]/\n/g")
	do
		# Append entry
		echo -e "$entry" >> $ACL_WHITELIST_FILE
	done
fi

# Disables admin endpoints on AAC service
if [[ "$ENABLE_ADMIN_ENDPOINTS" = "False" || "$ENABLE_ADMIN_ENDPOINTS" = "false" ]]; then
	parameters_config=`find /opt -name parameters.config`
	sed -i '/-gov.ic.cte.aac.config.activate.admin.endPoints/d' $parameters_config
	echo "-gov.ic.cte.aac.config.activate.admin.endPoints=false" >> $parameters_config
fi

# Enable Debugging and Java memory management
WRAPPER_FILES=`find / -name wrapper.conf`

for wrapper_file in $WRAPPER_FILES; do
    grep -q "wrapper.ignore_sequence_gaps=TRUE" $wrapper_file || echo 'wrapper.ignore_sequence_gaps=TRUE' >> $wrapper_file

    if [[ "$DEBUG" = "TRUE" || "$DEBUG" = "true" ]]; then
        echo "Enabling DEBUG mode"
        grep -q "wrapper.java.additional.100=-Xdebug -Xnoagent -Djava.compiler=NONE" $wrapper_file || echo "wrapper.java.additional.100=-Xdebug -Xnoagent -Djava.compiler=NONE" >> $wrapper_file
        grep -q "wrapper.java.additional.101=-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=4000" $wrapper_file || echo "wrapper.java.additional.101=-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=4000" >> $wrapper_file

		sed -i "s/level=\"\([^\"]*\)\"/level=\"DEBUG\"/" $SERVICE_HOME/etc/logback.xml
    else
        sed -i '/wrapper.java.additional.100=-Xdebug -Xnoagent -Djava.compiler=NONE/d' $wrapper_file
        sed -i '/wrapper.java.additional.101=-Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=4000/d' $wrapper_file
    fi

    if [[ ${JAVA_XMS} ]]; then
      grep -q "wrapper.java.additional.102=-Xms" $wrapper_file || echo "wrapper.java.additional.102=-Xms$JAVA_XMS" >> $wrapper_file
    fi

    if [[ ${JAVA_XMX} ]]; then
      grep -q "wrapper.java.additional.103=-Xmx" $wrapper_file || echo "wrapper.java.additional.103=-Xmx$JAVA_XMX" >> $wrapper_file
    fi

done
