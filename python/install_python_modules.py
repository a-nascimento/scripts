#!/usr/local/bin/python3

import subprocess, sys, getopt, logging

def main(argv):
    PACKAGE = ''
    try:
        opts, args = getopt.getopt(argv, "hp:")
    except getopt.GetoptError:
        print("./launch_venv.py -p <package name>")
        sys.exit(2)
    for opt, arg in opts:
        if opt == "-h":
            print("./launch_venv.py -p <package name>")
            print(args) 
            sys.exit()
        elif opt in ("-p"):
            print("This is {}" .format(arg))
            PACKAGE = arg
            print(PACKAGE)
            
    
    try:
        print("We are installing {}" .format(PACKAGE))
        subprocess.check_call([sys.executable, "-m", "pip", "install", PACKAGE])
    except:
        print("Failed to install {} please check if you have an appropriate package" .format(PACKAGE))
    

# start the script
if __name__ == "__main__":
    main(sys.argv[1:])
