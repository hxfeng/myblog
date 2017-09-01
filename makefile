all:

	hexo g && hexo d && hexo clean
	git add .
	git commit -m "update"
	git push
