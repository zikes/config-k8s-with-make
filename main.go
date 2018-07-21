package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	for range time.Tick(time.Second * 5) {
		fmt.Printf("Hello, %s!\n", os.Getenv("HELLO"))
	}
}
