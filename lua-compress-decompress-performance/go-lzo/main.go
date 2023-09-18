package main

import (
	"bytes"
	"compress/zlib"
	"fmt"
	"os"

	"github.com/cyberdelia/lzo"
)

func main() {
	data, err := os.ReadFile("input.txt")
	if err != nil {
		fmt.Printf("can't read input file: %s\n", err)
		return
	}

	// lzo

	buflzo := new(bytes.Buffer)

	wlzo, err := lzo.NewWriterLevel(buflzo, lzo.BestCompression)
	if err != nil {
		fmt.Printf("lzo new writer: %s\n", err)
		return
	}

	if _, err := wlzo.Write(data); err != nil {
		fmt.Printf("lzo compress: %s\n", err)
		return
	}

	wlzo.Close()

	err = os.WriteFile("output-lzo.txt", buflzo.Bytes(), 0644)
	if err != nil {
		fmt.Printf("lzo write: %s\n", err)
		return
	}

	// zlib

	bufzlib := new(bytes.Buffer)

	wzlib, err := zlib.NewWriterLevel(bufzlib, zlib.BestCompression)
	if err != nil {
		fmt.Printf("zlib new writer: %s\n", err)
		return
	}

	if _, err := wzlib.Write(data); err != nil {
		fmt.Printf("zlib compress: %s\n", err)
		return
	}

	wzlib.Close()

	err = os.WriteFile("output-zlib.txt", bufzlib.Bytes(), 0644)
	if err != nil {
		fmt.Printf("zlib write: %s\n", err)
		return
	}
}
