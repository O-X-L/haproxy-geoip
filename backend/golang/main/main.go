package main

import (
	"fmt"
)

func welcome() {
	fmt.Printf("\n   ______           ________     __                __             \n")
	fmt.Println("  / ____/__  ____  /  _/ __ \\   / /   ____  ____  / /____  ______ ")
	fmt.Println(" / / __/ _ \\/ __ \\ / // /_/ /  / /   / __ \\/ __ \\/ //_/ / / / __ \\")
	fmt.Println("/ /_/ /  __/ /_/ // // ____/  / /___/ /_/ / /_/ / ,< / /_/ / /_/ /")
	fmt.Println("\\____/\\___/\\____/___/_/      /_____/\\____/\\____/_/|_|\\__,_/ .___/ ")
	fmt.Println("                                                         /_/      ")
	fmt.Printf("by Superstes (GPLv3)\n\n")
}

func main() {
	welcome()
	server()
}
