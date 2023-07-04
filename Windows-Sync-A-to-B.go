package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"

	"github.com/fsnotify/fsnotify"
)

// 同步文件夹A到文件夹B
func syncFolders(folderA, folderB string) {
	err := filepath.Walk(folderA, func(pathA string, info os.FileInfo, err error) error {
		if err != nil {
			fmt.Printf("访问文件夹A中的文件/文件夹时出错：%v\n", err)
			return nil
		}

		// 构造对应的文件夹B中的路径
		pathB := filepath.Join(folderB, pathA[len(folderA):])

		if info.IsDir() {
			// 创建对应的文件夹B
			err := os.MkdirAll(pathB, os.ModePerm)
			if err != nil {
				fmt.Printf("创建文件夹B时出错：%v\n", err)
			}
		} else {
			// 复制文件A到文件B
			err := copyFile(pathA, pathB)
			if err != nil {
				fmt.Printf("复制文件A到文件B时出错：%v\n", err)
			}
		}

		return nil
	})
	if err != nil {
		fmt.Printf("访问文件夹A时出错：%v\n", err)
	}
}

// 复制文件
func copyFile(src, dest string) error {
	sourceFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sourceFile.Close()

	destinationFile, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer destinationFile.Close()

	_, err = io.Copy(destinationFile, sourceFile)
	if err != nil {
		return err
	}

	return nil
}

func main() {
	folderA := "C:\\FolderA" // 文件夹A的路径
	folderB := "C:\\FolderB" // 文件夹B的路径

	// 初始化文件夹B
	err := os.MkdirAll(folderB, os.ModePerm)
	if err != nil {
		fmt.Printf("创建文件夹B时出错：%v\n", err)
		return
	}

	// 开始监视文件夹A的变动
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		fmt.Printf("创建文件夹监视器时出错：%v\n", err)
		return
	}
	defer watcher.Close()

	err = watcher.Add(folderA)
	if err != nil {
		fmt.Printf("添加文件夹A到监视器时出错：%v\n", err)
		return
	}

	fmt.Println("开始监视文件夹A的变动...")

	for {
		select {
		case event, ok := <-watcher.Events:
			if !ok {
				return
			}
			if event.Op&fsnotify.Write == fsnotify.Write || event.Op&fsnotify.Create == fsnotify.Create {
				fmt.Println("检测到文件夹A的变动，开始同步到文件夹B...")
				syncFolders(folderA, folderB)
				fmt.Println("同步完成！")
			}
		case err, ok := <-watcher.Errors:
			if !ok {
				return
			}
			fmt.Printf("监视器错误：%v\n", err)
		}
	}
}
