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

# Funktion that shows the main menu
show_Main_Menu() {
	clear
	echo "=========================================================="
	echo "	SYSTEM MANAGER (version 1.0.0) "
	echo "----------------------------------------------------------"
	echo
	echo "ci - Computer Info	(Computer information)"
 	echo 
  	echo "ua - User Add		(Create a new user)"
   	echo "ul - User Liew		(List all login users)"
    	echo "uv - User View		(View user properties)"
     	echo "um - User Modify		(Modify user properties)"
      	echo "ud - User Delete		(Delete a login user)"
       	echo
	echo
 	echo "ga - Group Add		(Create a new group)"
  	echo "gl - Group List		(List all groups, not system groups)"
   	echo "gv - Group View		(List all users in a group)"
    	echo "gm - Group Modify		(Add/remove user to/from a group)"
     	echo "gd - Group Delete		(Delete a group, not system groups)"
	echo
 	echo
  	echo "fa - Folder Add		(create a new folder)"
   	echo "fl - Folder list		(view content in a folder)"
    	echo "fv - Folder View		(View folder properteis)"
     	echo "fm - Folder Modify	(modify folder properties)"
      	echo "fd - Folder Delete	(Delete a folder)"
	echo "X - Exit the system manager"
	echo "----------------------------------------------------------"
	echo
	read -p "Choice: " choice
	case $choice in
		ci) computer_Info ;; 	# Call the funtion to display computer info
  		ua) add_User ;; 	# Call the funktion for creating a user
    		ul) ;;			# Placeholder for listing all users
		uv) ;;                  # Placeholder for viewing user properties
  		um) ;;			# Placeholder for modifying user properties
    		ud) ;;			# Placeholder for deleting a user
      		ga) ;;			# Placeholder for adding a group
		gl) ;;			# Placeholder for listing groups
  		gv) ;;			# Placeholder for viewing users in a group
    		gm) ;;			# Placeholder for modifying group membership
      		gd) ;; 			# Placeholder for deleting a group
      		fa) ;;			# Placeholder for adding a folder
		fl) ;;			# Placeholder for listing folder contents
  		fv) ;;			# Placeholder for viewing folder properties
    		fm) ;;			# Placeholder for modifying folder properties
      		fd) ;;			# Placeholder for deleting a folder
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
add_User(){
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
      		useradd -m "$username" # Creates a user with a home directory
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

# Exits the script
exit_Script() {
	clear
	echo "Exiting script. Bye"
	exit 0
}
while true; do
	show_Main_Menu
done
