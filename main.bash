#!/bin/bash

#
#Skapad av Casper Hjorth och Eric Pettersson, grupp 32
#
# Licens: MIT License
#
# Motivering: vi valde MIT license för att den är enkelt och till[ter fri användning, modifiering och distribution av koden.
#

# controlls that the script is running with root acces if not it explains it and exits
if [[ $EUID -ne 0 ]]; then
	echo "Detta skript måste köras som  root (sudo). Avslutar."
	exit 1
fi

show_Main_Menu(){
    clear
    echo "=========================================================="
    echo "          SYSTEM MANAGER (version 1.0.0)"
    echo "----------------------------------------------------------"
    echo

    # Sektion: Computer Info
    printf "%-25s %s\n" "ci - Computer Info" "(Computer information)"
    echo

    # Sektion: User Management
    printf "%-25s %s\n" "ua - User Add" "(Create a new user)"
    printf "%-25s %s\n" "ul - User List" "(List all login users)"
    printf "%-25s %s\n" "uv - User View" "(View user properties)"
    printf "%-25s %s\n" "um - User Modify" "(Modify user properties)"
    printf "%-25s %s\n" "ud - User Delete" "(Delete a login user)"
    echo

    # Sektion: Group Management
    printf "%-25s %s\n" "ga - Group Add" "(Create a new group)"
    printf "%-25s %s\n" "gl - Group List" "(List all groups, not system groups)"
    printf "%-25s %s\n" "gv - Group View" "(List all users in a group)"
    printf "%-25s %s\n" "gm - Group Modify" "(Add/remove user to/from a group)"
    printf "%-25s %s\n" "gd - Group Delete" "(Delete a group, not system groups)"
    echo

    # Sektion: Folder Management
    printf "%-25s %s\n" "fa - Folder Add" "(Create a new folder)"
    printf "%-25s %s\n" "fl - Folder List" "(View content in a folder)"
    printf "%-25s %s\n" "fv - Folder View" "(View folder properties)"
    printf "%-25s %s\n" "fm - Folder Modify" "(Modify folder properties)"
    printf "%-25s %s\n" "fd - Folder Delete" "(Delete a folder)"
    echo

    # Exit option
    printf "%-25s %s\n" "X - Exit" "(Exit the System Manager)"
    echo "----------------------------------------------------------"
    echo

    # Prompt for user choice
    read -p "Choice: " choice
    case $choice in
        ci) computer_Info ;;
        ua) user_Add ;;
        ul) user_List ;;
        uv) user_View ;;
        um) user_Modify ;;
        ud) user_Delete ;;
        ga) group_Add ;;
        gl) group_List ;;
        gv) group_View ;;
        gm) group_Modify ;;
        gd) group_Delete ;;
        fa) folder_Add ;;
        fl) folder_List ;;
        fv) folder_View ;;
        fm) folder_Modify ;;
        fd) folder_Delete ;;
        X) exit_Script ;;
        *) echo "Invalid choice, try again."; sleep 2 ;;
    esac
}
#Shows general computer information
computer_Info() {
	clear
	echo "=========================================================="
	echo " 		 SYSTEM MANAGER (version 1.0.0)"
	echo "			Computer information "
	echo "----------------------------------------------------------"
	echo 
	printf "%-18s: %s\n" "Computer name" "$(hostname)"
	printf "%-18s: %s\n" "OS Description" "$(lsb_release -d | cut -f2)"
	printf "%-18s: %s\n" "Linux Kernel" "$(uname -r)"
	printf "%-18s: %s\n" "CPU" "$(lscpu | grep 'Model name' | awk -F':' '{print $2}' | xargs)"
	printf "%-18s: %s\n" "Total memory" "$(free -h | grep 'Mem:' | awk '{print $2}' | sed 's/Gi/GB/')"
	printf "%-18s: %s\n" "Free disk space" "$(df -h --output=avail,pcent / | awk 'NR==2 {printf "%s (%s)", $1, $2}')" #shows the avalible disk space and its usage percentage for the root partition.
 	printf "%-18s: %s\n" "IP-address" "$(hostname -I | xargs)"
	
	echo
	echo "----------------------------------------------------------"
	echo
	read -p "Press enter to continue... " enter
}
#Funktion för att lägga till en ny användare
user_Add(){
	clear
	echo "=========================================================="
	echo " 		 SYSTEM MANAGER (version 1.0.0)"
	echo "			Add a New User "
	echo "----------------------------------------------------------"
	echo 

	 # Prompt for the username
 	read -p "Enter the username for the new user: " username

  	# Cheack if the user already exists
   	if id "$username" &>/dev/null; then
    	echo "Error: The user '$username' already exists."
      	read -p "Press enter to return to the menu..." enter
		return
  	fi

	read -p "Enter a comment (e.g., full name) for the user [optional]: " comment 

    # Create the user
    if [[ -z $comment ]]; then
		useradd -m -s /bin/bash "$username" # Skapar en user med hemkatalog och skal
	else
 		useradd -m -c "$comment" "$username" # Creates a user with a comment
   	fi

	# Check if the user was created successfully
   	if [[ $? -eq 0 ]]; then # $? håller exit statusen på det senaste kommandot om == 0 så fungerade det som det ska -eq = ==
		echo "The user '$username' has been created successfully."
        
  		# Prompt to set a password for the new user
    	passwd "$username"
    	if [[ $? -eq 0 ]]; then 
      		echo "Password has been set for user '$username'."
     	else
      		echo "Error: Failed to set password for user '$username'."
     	fi
	else
		echo "Error: Failed to create the user '$username'."
   	fi

  	read -p "Press enter to return to the menu... " enter
}

#Funktion för att lista användare
user_List(){
	clear
	echo "=========================================================="
	echo " 		 SYSTEM MANAGER (version 1.0.0)"
	echo "			List of Login Users"
	echo "----------------------------------------------------------"
	echo 
	echo -e "USERNAME	FULL NAME		HOME DIRECTORY"
 	# Lista alla användare med UID >= 1000 och giltiga sakl
  	awk -F: '$3 >= 1000 && $7 !~ /nologin|false/ {printf "%-15s %-20s %-20s\n", $1, $5, $6}' /etc/passwd # $1:användarnamn $5:kommentar $6:hemkatalog
   	
	echo
	echo "----------------------------------------------------------"
 	echo
  	read -p "Press Enter to return to the menu... " enter
}

# Funktionen som vissar all information som finns med i /etc/passwd och vilka grupper en användare tillhör
user_View(){
	clear
	echo "=========================================================="
	echo " 		 SYSTEM MANAGER (version 1.0.0)"
	echo "			User view"
	echo "----------------------------------------------------------"
	echo 

 	# Be användaren om en user
  	read -p "Properties for user: " username

 	# Kollar om användaren finns
  	if ! id "$username" &>/dev/null; then
		echo "The user '$username' does not exist."
  		echo "----------------------------------------------------------"
  		read -p "Press enter to return to the menu..." enter
    	return
    fi

 	# Hämta användarens information från /etc/passwd
  	user_info=$(getent passwd "$username")
   	IFS=':' read -r uname passwd uid gid comment home shell <<< "$user_info"

	groups=$(id -nG "$username" | tr ' ' ',  ') #listar grupper användaren tillhör och omvandlar till , separerad lista.

 	echo "Properties for user: $username"
	echo 
 	printf "%-18s: %s\n" "User" "$uname"
  	printf "%-18s: %s\n" "Password" "$passwd"
   	printf "%-18s: %s\n" "User ID" "$uid"
    printf "%-18s: %s\n" "Group ID" "$gid"
    printf "%-18s: %s\n" "Comment" "$comment"
	printf "%-18s: %s\n" "Directory" "$home"
	printf "%-18s: %s\n" "Shell" "$shell"
	echo

 	printf "%-18s: %s\n" "Groups" "$groups"
      	
  	echo "----------------------------------------------------------"
   	echo
    read -p "Press Enter to return to the menu... " enter
}

#Funktion för att modifiera en användare
user_Modify() {
    clear
    echo "=========================================================="
    echo " 		 SYSTEM MANAGER (version 1.0.0)"
    echo "			Modify User"
    echo "----------------------------------------------------------"
    echo 

    # Be om användarnamn
    read -p "Enter the username to modify: " username

    # Kontrollera om användaren finns
    if ! id "$username" &>/dev/null; then
        echo "The user '$username' does not exist."
        echo "----------------------------------------------------------"
        read -p "Press enter to return to the menu..." enter
        return
    fi

    # Visa nuvarande attribut för användaren från /etc/passwd
    user_info=$(getent passwd "$username")
    IFS=':' read -r uname passwd uid gid comment home shell <<< "$user_info"

    echo "Current attributes for user '$username':"
    printf "%-18s: %s\n" "Username" "$uname"
    printf "%-18s: %s\n" "User ID" "$uid"
    printf "%-18s: %s\n" "Group ID" "$gid"
    printf "%-18s: %s\n" "Comment" "$comment"
    printf "%-18s: %s\n" "Home Directory" "$home"
    printf "%-18s: %s\n" "Shell" "$shell"
    printf "%-18s: %s\n" "Password" "$passwd"
    echo "----------------------------------------------------------"

    # Alternativ för att ändra attribut
    echo "What do you want to modify?"
    echo "1. Username"
    echo "2. User ID"
    echo "3. Group ID"
    echo "4. Comment (Full Name/Description)"
    echo "5. Home Directory"
    echo "6. Shell"
    echo "7. Password" 
    echo "8. Cancel"
    
    read -p "Choice [1-8]: " choice

	case $choice in
	1) 
 	    read -p "Enter the new username: " new_username
	    sudo usermod -l "$new_username" "$username" &>/dev/null
     
	    if [ $? -eq 0 ]; then
  			echo "Your username has been changed"
	    else
  			echo "ERROR: You cannot have this username."
	    fi
	;;
    
    	2) 
		read -p "Enter the new user id: " user_id
		if [[ "$user_id" -gt 1000 ]]; then
	    		sudo usermod -u "$user_id" "$username" &>/dev/null
	    		if [ $? -eq 0 ]; then
  				echo "Your user id has been changed to $user_id"
	    		else
  				echo "You cannot have this user id"
	    		fi
		else
 			echo "This User ID is already taken"
 		fi
	;;
	    
    	3)
		read -p "Enter the new group id: " group_id
		if [[ "$group_id" -gt 1000 ]]; then
	    		sudo usermod -g "$group_id" "$username" &>/dev/null
            			if [ $? -eq 0 ]; then
  					echo "The group ID has been changed"
            			else
  					echo "You cannot have this group ID"
            			fi    
			else
 				echo "The group ID has to be above 1000"
   			fi
	;;
	
 	4)
        read -p "Enter new comment: " new_comment
        sudo usermod -c "$new_comment" "$username"
        if [[ $? -eq 0 ]]; then
            echo "Comment updated successfully for user '$username'."
        else
            echo "Failed to update comment for user '$username'."
        fi
    ;;
	
    5)
        read -p "Enter new home directory (full path): " new_home
        sudo usermod -d "$new_home" -m "$username"  # -m flyttar filer till den nya katalogen
        if [[ $? -eq 0 ]]; then
        	echo "Home directory updated successfully for user '$username'."
        else
            echo "Failed to update home directory for user '$username'."
        fi
    ;;
    6)
        read -p "Enter new shell (e.g., /bin/bash): " new_shell
        sudo usermod -s "$new_shell" "$username"
        if [[ $? -eq 0 ]]; then
            echo "Shell updated successfully for user '$username'."
        else
            echo "Failed to update shell for user '$username'."
        fi
    ;;
	
    7)
		echo "Changing password for user '$username'..."
        sudo passwd "$username"
        if [[ $? -eq 0 ]]; then
            echo "Password updated successfully for user '$username'."
        else
            echo "Failed to update password for user '$username'."
        fi
    ;;
	
    8)
        echo "Modification canceled."
    ;;
	
    *)
        echo "Invalid choice. Returning to the menu."
    ;;
    esac
	
    echo "----------------------------------------------------------"
    read -p "Press enter to return to the menu..." enter
}

# Function to remove a user and their home directory
user_Delete() {
    clear
    echo "=========================================================="
    echo " 		 SYSTEM MANAGER (version 1.0.0)"
    echo "			Delete user"
    echo "----------------------------------------------------------"
    echo 
	 
    # Ask for the username
    read -p "Enter the username to remove: " username

    # Check if the user exists
    if ! id "$username" &>/dev/null; then
        echo "The user '$username' does not exist."
        echo "----------------------------------------------------------"
        read -p "Press enter to return to the menu..." enter
        return
    fi

    # Confirm the removal
    read -p "Are you sure you want to remove $username (Y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Remove the user and their home directory
        sudo userdel -r "$username" &>/dev/null
        if [[ $? -eq 0 ]]; then 
            echo "The user '$username' and their home directory have been removed successfully."
        else
            echo "An error occurred during the removal of the user."
        fi
    else
        echo "The removal was canceled."
    fi
    echo "----------------------------------------------------------"
    read -p "Press enter to return to the menu..." enter
}

#Funktion för att Skapa nya grupper
group_Add() {
    clear
    echo "=========================================================="
    echo "          SYSTEM MANAGER (version 1.0.0)"
    echo "             Add a New Group"
    echo "----------------------------------------------------------"
    echo

    read -p "Enter the group name: " groupname

    #Kollar om gruppen redan existerar
    if getent group "$groupname" &>/dev/null; then
        echo "Error: The group '$groupname' already exists."
        read -p "Press enter to return to the menu..." enter  
	return
    fi

    #Skapar nya gruppen
    groupadd "$groupname"
    if [[ $? -eq 0 ]]; then
        echo "The group '$groupname' has been created successfully."
    else
        echo "Error: Failed to create the group '$groupname'."
    fi

    read -p "Press enter to return to the menu..." enter
}

#Funktion för att Lista grupper
group_List(){
	clear
    echo "=============================================================="
  	echo "          SYSTEM MANAGER (version 1.0.0)"
   	echo "             List of Non-System Groups"
    echo "--------------------------------------------------------------"
   	echo 	

    #Lista alla grupper med GID >=1000
    awk -F: '$3 >= 1000 {printf "%-20s %-10s\n", $1, $3}' /etc/group

    echo
	echo "---------------------------------------------------------------"
    read -p "Press enter to return to the menu..." enter
}

group_View(){
    clear
    echo "=========================================================="
    echo "          SYSTEM MANAGER (version 1.0.0)"
    echo "             Users in a Specific Group"
    echo "----------------------------------------------------------"
    echo

    # Be användaren om ett gruppnamn
    read -p "Enter the group name: " groupname

    # Kontrollera om gruppen finns
    if ! getent group "$groupname" &>/dev/null; then
        echo "The group '$groupname' does not exist."
        echo "----------------------------------------------------------"
        read -p "Press enter to return to the menu..." enter
        return
    fi

    # Hämta GID för gruppen
    group_gid=$(getent group "$groupname" | cut -d: -f3)

    # Lista användare med gruppen som primärgrupp (från /etc/passwd)
    primary_users=$(awk -F: -v gid="$group_gid" '$4 == gid {print $1}' /etc/passwd)

    # Lista användare som är medlemmar i gruppen (från /etc/group)
    secondary_users=$(getent group "$groupname" | awk -F: '{print $4}' | tr ',' '\n')

    echo "Users in group '$groupname':"
    echo
    echo "Primary group members:"
    if [[ -n "$primary_users" ]]; then
        echo "$primary_users"
    else
        echo "None"
    fi
    echo
    echo "Secondary group members:"
    if [[ -n "$secondary_users" ]]; then
        echo "$secondary_users"
    else
        echo "None"
    fi

    echo "----------------------------------------------------------"
    read -p "Press enter to return to the menu..." enter
}

#Funktion för att ta bort eller lägga till en användare i en grupp
group_Modify(){
	clear
    echo "=========================================================="
   	echo "          SYSTEM MANAGER (version 1.0.0)"
   	echo "            Add or remove a user from group"
   	echo "----------------------------------------------------------"
    echo

    # Be användaren om ett grupp namn
 	read -p "Enter the group name: " groupname

  	# Kontrollera om gruppen finns
   	if ! getent group "$groupname" &>/dev/null; then
    	echo "The group '$groupname' does not exist."
      	echo "----------------------------------------------------------"
		read -p "Press enter to return to the menu..." enter
  		return
    fi

	# Alternativ för att lägga till eller ta bort användare
 	echo "What would you like to do?"
  	echo "1. add a user to the group"
   	echo "2. Remove a user from the group"
    echo "3. Cancel"
    read -p "Choice [1-3]: " choice

    case $choice in 
	1)
		# Lägg till en användare
		read -p "Enter the username to add: " username
       	if id "$username" &>/dev/null; then
			sudo usermod -aG "$groupname" "$username"
      		if [[ $? -eq 0 ]]; then
	  			echo "User '$username' has been added to group '$groupname'."
       		else
	   			echo "Failed to add user '$username' to group "$groupname"."
			fi
    	else
       		echo "The user '$username' does not exist."
	   	fi
	;;
 
 	2)
		#ta bort en användare
		read -p "Enter the username to remove: " username
   		if id "$username" &>/dev/null; then
      		current_groups=$(id -nG "$username" | tr ' ' ',')
	  		updated_groups=$(echo "$current_groups" | sed "s/\b$groupname\b//g" | sed 's/,,/,/g' | sed 's/^,//' | sed 's/,$//') # tar bort gruppen, tar bort överflödiga , tecken. tar bort , tecken i början och slutet
            sudo usermod -G "$updated_groups" "$username"
            if [[ $? -eq 0 ]]; then
            	echo "User '$username' has been removed from group '$groupname'."
            else
            	echo "Failed to remove user '$username' from group '$groupname'."
            fi
        else
        	echo "The user '$username' does not exist."
        fi
	;;
 
  	3)
    	echo "Modification canceled."
    ;;
	
    *)
    	echo "Invalid choice. Returning to the menu."
    ;;
	
    esac
	
   	echo "----------------------------------------------------------"
    read -p "Press enter to return to the menu..." enter
}

#Funktion för att ta bort en grupp
group_Delete(){
    clear
    echo "=========================================================="
    echo "          SYSTEM MANAGER (version 1.0.0)"
    echo "             Delete Group"
    echo "----------------------------------------------------------"
    echo

    #Frågar efter gruppnamn
    read -p "Enter the group name to delete: " groupname

    #Kollar att gruppen existerar
    if ! getent group "$groupname" &>/dev/null; then
        echo "The group '$groupname' does not exist."
        read -p "Press enter to return to the menu..." enter
        return
    fi
	
    group_gid=$(getent group "$groupname" | cut -d: -f3)
	
    if [[ "$group_gid" -lt 1000 ]]; then
    	echo "You can not remove that group"
     	read -p "Press enter to return to the menu..." enter
    	return
    fi

    #Bekräfta borttagningen 
    read -p "Are you sure you want to remove $groupname (Y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        groupdel "$groupname"
        if [[ $? -eq 0 ]]; then 
            echo "The group '$groupname' has been removed successfully."
        else
            echo "An error occurred during the removal of the group."
        fi
    else
        echo "The removal was canceled."
    fi

    read -p "Press enter to return to the menu..." enter
}

#Funktion för att skapa en ny mapp
folder_Add() {
    clear  
    echo "=========================================================="
    echo "          SYSTEM MANAGER (version 1.0.0)"
    echo "             Add a New Folder"
    echo "----------------------------------------------------------"
    echo

    read -p "Enter Folder Name: " folder_name

    #Kollar om mappen redan finns
    if [ -d "$folder_name" ]; then
        echo "Folder $folder_name already exists. Please enter another folder name."
        read -p "Press enter to continue" enter
    else
        mkdir "$folder_name"  
        echo "The folder $folder_name has been created."
    fi
}
# Funktion för att lista mappinnehåll
folder_List() {
    clear
    echo "=========================================================="
    echo "          SYSTEM MANAGER (version 1.0.0)"
    echo "             List Folder Contents"
    echo "----------------------------------------------------------"
    echo

    ls -l | grep "^d" | awk '{print $9}' | sort
    read -p "Enter the folder path to list: " folder_path

    # Kollar att mappen existerar
    if [ -d "$folder_path" ]; then
        echo "Contents of folder '$folder_path':"
        ls "$folder_path"
    else
        echo "The folder does not exist."
    fi

    read -p "Press enter to continue..." enter
}

folder_View() {
    clear
    echo "=========================================================="
    echo "          SYSTEM MANAGER (version 1.0.0)"
    echo "             View Folder Properties"
    echo "----------------------------------------------------------"
    echo
    
    read -p "Enter the folder path to view: " folder_path

    # Kontrollera om mappen existerar
    if [ -d "$folder_path" ]; then
        echo "Folder: $folder_path"
        echo "----------------------------------------------------------"

        # Lista attribut
        permissions=$(ls -ld "$folder_path" | awk '{print $1}')
        owner=$(ls -ld "$folder_path" | awk '{print $3}')
        group=$(ls -ld "$folder_path" | awk '{print $4}')
        size=$(du -sh "$folder_path" | awk '{print $1}')
        last_modified=$(stat -c '%y' "$folder_path")
		sticky_bit=$(stat -c '%A' "$folder_path" | grep -q '[tT]' && echo "On" || echo "Off")
		setgid=$(stat -c '%A' "$folder_path" | grep -q '[sS]' && echo "On" || echo "Off")

        # Visa attribut
        echo "Owner:           $owner"
        echo "Group:           $group"
        echo "Permissions: "
		echo
		echo "$(translate_permissions "$permissions")"
        echo "Sticky Bit:      $sticky_bit"
		echo
        echo "Setgid:          $setgid"
        echo "Size:            $size"
        echo "Last Modified:   $last_modified"
        echo "----------------------------------------------------------"
    else
        echo "ERROR: Folder '$folder_path' does not exist."
    fi
	
    read -p "Press enter to return to the menu..." enter
}

folder_Modify() {
    clear
    echo "=========================================================="
    echo "          SYSTEM MANAGER (version 1.0.0)"
    echo "        List and Modify Folder Attributes"
    echo "----------------------------------------------------------"
    echo

    read -p "Enter the folder path to manage: " folder_path

    # Kontrollera om mappen finns
    if [ -d "$folder_path" ]; then
        clear
        echo "Current Properties of the Folder:"
        echo "----------------------------------------------------------"

        # Lista attribut
        permissions=$(ls -ld "$folder_path" | awk '{print $1}')
        owner=$(ls -ld "$folder_path" | awk '{print $3}')
        group=$(ls -ld "$folder_path" | awk '{print $4}')
        size=$(du -sh "$folder_path" | awk '{print $1}')
        last_modified=$(stat -c '%y' "$folder_path")
		sticky_bit=$(stat -c '%A' "$folder_path" | grep -q '[tT]' && echo "On" || echo "Off")
		setgid=$(stat -c '%A' "$folder_path" | grep -q '[sS]' && echo "On" || echo "Off")

        # Visa attribut
        echo "Owner:           $owner"
        echo "Group:           $group"
        echo "Permissions:     $(translate_permissions "$permissions")"
        echo "Sticky Bit:      $sticky_bit"
        echo "Setgid:          $setgid"
        echo "Size:            $size"
        echo "Last Modified:   $last_modified"
        echo "----------------------------------------------------------"

        # Ändra attribut
        echo "What would you like to modify?"
        echo "1. Change Owner"
        echo "2. Change Group"
        echo "3. Change Permissions (User-Friendly)"
        echo "4. Change Permissions (Advanced Mode)"
        echo "5. Toggle Sticky Bit"
        echo "6. Toggle Setgid"
        echo "7. Cancel"
        echo "----------------------------------------------------------"
        read -p "Enter your choice [1-7]: " choice

        case $choice in
    		1)
                clear
                read -p "Enter the new owner (username): " owner
                if sudo chown "$owner" "$folder_path"; then
                    echo "Owner successfully updated to '$owner'."
                else
                    echo "ERROR: Unable to update owner."
                fi
                ;;
				
            2)
                clear
                read -p "Enter the new group: " group
                if sudo chgrp "$group" "$folder_path"; then
                    echo "Group successfully updated to '$group'."
                else
                    echo "ERROR: Unable to update group."
                fi
                ;;
				
            3)
				clear
    			echo "Current Permissions: $(ls -ld "$folder_path" | awk '{print $1}')"
    			echo "----------------------------------------------------------"
    			echo "Select new permissions for the folder:"
    			echo

    			# Function to get permission input from the user
    			set_permissions() {
        		read -p "Enter your choice [1-4]: " choice

        		case $choice in
            		1) echo "rwx" ;;  # Full access
            		2) echo "rw-" ;;  # Read and write
            		3) echo "r--" ;;  # Read-only
            		4) echo "---" ;;  # No access
            		*) echo "---" ;;  # Default to no access
       		 	esac
    			}

    			echo "Set permissions for:"
    			echo
    			echo "1. Read, Write, Execute (Full acces)"
    			echo "2. Read, Write (Modify but not execute)"
    			echo "3. Read Only"
    			echo "4. No Permission"
    			echo "----------------------------------------------------------"
	   
    			# Get permissions for the owner
    			echo "Owner:"
    			owner_perms=$(set_permissions)
			    echo

    			# Get permissions for the group
    			echo "Group:"
    			group_perms=$(set_permissions)
    			echo

    			# Get permissions for others
    			echo "Others:"
    			other_perms=$(set_permissions)

    			# Apply the permissions using three separate chmod commands
					if chmod "u=$owner_perms" "$folder_path" &&
	   				chmod "g=$group_perms" "$folder_path" &&
       				chmod "o=$other_perms" "$folder_path"; then
			
        				echo "Permissions successfully updated to:"
        				echo "Owner: $owner_perms"
        				echo "Group: $group_perms"
        				echo "Others: $other_perms"
    				else
        				echo "ERROR: Unable to update permissions."
    				fi
    		;;
	  
            4)
                clear
                read -p "Enter the new permissions (e.g., 755): " permissions
                if sudo chmod "$permissions" "$folder_path"; then
                    echo "Permissions successfully updated to '$permissions'."
                else
                    echo "ERROR: Unable to update permissions."
                fi
            ;;
			
			5)
    			clear
    			echo "Toggle Sticky Bit for the folder:"
    			echo "1. Set Sticky Bit"
    			echo "2. Remove Sticky Bit"
    			read -p "Enter your choice [1-2]: " sticky_choice

    			if [[ "$sticky_choice" -eq 1 ]]; then
        			sudo chmod +t "$folder_path"
        			if [[ $? -eq 0 ]]; then
		   
            			# Kontrollera om Sticky Bit är satt (antingen liten eller stor 't')
            			permissions=$(stat -c '%A' "$folder_path")
            			if [[ "${permissions:9:1}" == "t" || "${permissions:9:1}" == "T" ]]; then
                			echo "Sticky Bit set."
            			else
                			echo "ERROR: Sticky Bit not set as expected."
            			fi
        			else
            			echo "ERROR: Unable to set Sticky Bit."
        			fi
		   
    				elif [[ "$sticky_choice" -eq 2 ]]; then
        				sudo chmod -t "$folder_path"
        				if [[ $? -eq 0 ]]; then
			
            				# Kontrollera om Sticky Bit är borttaget
            				permissions=$(stat -c '%A' "$folder_path")
            				if [[ "${permissions:9:1}" != "t" || "${permissions:9:1}" != "T" ]]; then
                				echo "Sticky Bit removed."
            				else
                				echo "ERROR: Sticky Bit not removed as expected."
            				fi
        				else
            				echo "ERROR: Unable to remove Sticky Bit."
        				fi
    				else
        				echo "Invalid choice."
    			fi
    		;;
	  
			6)
    			clear
    			echo "Toggle Setgid for the folder:"
    			echo "1. Set Setgid"
    			echo "2. Remove Setgid"
    			read -p "Enter your choice [1-2]: " setgid_choice

    			if [[ "$setgid_choice" -eq 1 ]]; then
        			sudo chmod g+s "$folder_path"
        			if [[ $? -eq 0 ]]; then
		   
            			# Kontrollera om Setgid är satt (antingen liten eller stor 's')
            			permissions=$(stat -c '%A' "$folder_path")
            			if [[ "${permissions:6:1}" == "s" || "${permissions:6:1}" == "S" ]]; then
                			echo "Setgid set."
            			else
                			echo "ERROR: Setgid not set as expected."
            			fi
        			else
            			echo "ERROR: Unable to set Setgid."
        			fi
		   
    			elif [[ "$setgid_choice" -eq 2 ]]; then
        			sudo chmod g-s "$folder_path"
        			if [[ $? -eq 0 ]]; then
		   
            			# Kontrollera om Setgid är borttaget
            			permissions=$(stat -c '%A' "$folder_path")
            			if [[ "${permissions:6:1}" != "s" || "${permissions:6:1}" != "S" ]]; then
                			echo "Setgid removed."
            			else
							echo "ERROR: Setgid not removed as expected."
            			fi
        			else
            			echo "ERROR: Unable to remove Setgid."
        			fi
    			else
        			echo "Invalid choice."
    			fi
    		;;
	  
            7)
                echo "Modification canceled. Returning to menu."
            ;;
			
            *)
                echo "Invalid input. Returning to menu."
            ;;
        	esac
    		else
        		echo "ERROR: Folder '$folder_path' does not exist. Please enter a valid folder path."
    		fi

    		echo "----------------------------------------------------------"
    		read -p "Press enter to return to the menu..." enter
}

# Funktion för att översätta rättigheter
translate_permissions() {
    local perms=$1
    local result=""

    # Owner
    [[ ${perms:1:1} == "r" ]] && result+="Owner: Read " || result+="Owner: No Read "
    [[ ${perms:2:1} == "w" ]] && result+="Write " || result+="No Write "
    [[ ${perms:3:1} == "x" ]] && result+="Execute\n" || result+="No Execute\n"

    # Group
    [[ ${perms:4:1} == "r" ]] && result+="Group: Read " || result+="Group: No Read "
    [[ ${perms:5:1} == "w" ]] && result+="Write " || result+="No Write "
    [[ ${perms:6:1} == "x" ]] && result+="Execute\n" || result+="No Execute\n"

    # Others
    [[ ${perms:7:1} == "r" ]] && result+="Others: Read " || result+="Others: No Read "
    [[ ${perms:8:1} == "w" ]] && result+="Write " || result+="No Write "
    [[ ${perms:9:1} == "x" ]] && result+="Execute" || result+="No Execute"

    echo -e "$result"
}

folder_Delete() {
    clear
    echo "=========================================================="
    echo "          SYSTEM MANAGER (version 1.0.0)"
    echo "             Delete Folder"
    echo "----------------------------------------------------------"
    echo

    read -p "Enter the folder path to delete: " folder_path

    #Kollar att mappen existerar
    if [ -d "$folder_path" ]; then
        rm -r "$folder_path"
        echo "The folder '$folder_path' has been deleted."
    else
        echo "The folder does not exist."
    fi

    read -p "Press enter to return to the menu..." enter
}

# Exits the script
exit_Script() {
	clear
	echo "Exiting script. Bye"
	exit 0
}
while true; do
	show_Main_Menu
done
