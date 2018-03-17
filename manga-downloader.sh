#!/bin/bash
#Copyright 2013-2017 Fabian Ebner and others
#Published under the GPLv3 or any later version, see the file COPYING for details

function tac_awk()
{
	cat $1 | awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }'
}

function imgurl_firstimgtag()
{
	imgurl=`cat temporary.html | awk '{split($0,a,"<img");$1=a[2];print $1}' | awk '{split($0,a,"src=\"");$1=a[2];print $1}' | awk '{split($0,a,"\"");$1=a[1];print $1}'`
}

function imgurl_firstimgtag_class_open()
{
	imgurl=`cat temporary.html | awk '{split($0,a,"<img class=\"open\"");$1=a[2];print $1}' | awk '{split($0,a,"src=\"");$1=a[2];print $1}' | awk '{split($0,a,"\"");$1=a[1];print $1}'`
}

function imgurl_filter_manganame()
{
	imgurl=`echo $imgurl | grep $manganame`
}

function imgurl_filter_firstresult()
{
	imgurl=`echo $imgurl | grep http | head -n 1 | cut -d ' ' -f 1`
}

function imgurl_filter_secondresult()
{
	imgurl=`echo $imgurl | grep http | cut -d ' ' -f 2`
}

function error_imgurl()
{
	echo "This shouldn't happen. Please try again and if it still fails, report a bug at github.com/briefbanane/manga-downloader"
	echo "and include the last URL: $url image-URL: $imgurl and curl-return: $curlreturn"
	exit 2
}

function error_url()
{
	echo "Cannot handle URL. Please check again and eventually report a bug at github.com/briefbanane/manga-donwloader"
	echo "and include the URL: $url"
	exit 1
}

function download()
{
	curlreturn=18
	insecureflag=""
	while [ $curlreturn -eq 18 ]
	do
		curl $insecureflag -g -s -A "Mozilla/5.0 (X11; Linux x86_64; rv:55.0)" --compressed --max-redirs 0 $1 -o $2 -C -
		curlreturn=$?
		if [ $curlreturn -eq 60 ]
		then
			read -r -p "Secure connection could not be authenticated. Use insecure connection? (Y/n): " rep
			rep=${rep,,}
			if [[ $rep =~ ^(yes|y| ) ]] || [[ -z $rep ]]
			then
				insecureflag="-k"
				curlreturn=18
			else
				echo "Aborting"
				exit 3
			fi
		fi
	done
}

function download_image()
{
	fail=1
	while [ $fail -ne 0 ]
	do
		curlreturn=18
		while [ $curlreturn -eq 18 ]
		do
			curl -g -s -A "Mozilla/5.0 (X11; Linux x86_64; rv:55.0)" --compressed --max-redirs 0 "$1" -o $2 -C -
			curlreturn=$?
		done
		if [ ! -e $2 ]
		then
			fail=1
		else
			fail=`file $2 | grep -v image | wc -l`
		fi
		if [ $fail -ne 0 ]
		then
			echo "Download not successful, trying again"
			rm $2
		fi
	done
}

function base_manganame_chapternum_pagenum_downloader()
{
	mkdir -p $manganame
	cd $manganame

	while [ true ]
	do
		url="http://$base/$manganame/$chapternum/$pagenum"
		rm -f temporary.html
		download $url "temporary.html"
		if [ $curlreturn -ne 0 ]
		then
			echo "All chapters (`expr $chapternum - 1`) downloaded"
			rm -f temporary.html
			exit 0
		fi
		mkdir -p chapter-$chapternum
		cd chapter-$chapternum
		while [ $curlreturn -eq 0 ]
		do
			url="http://$base/$manganame/$chapternum/$pagenum"
			rm -f temporary.html
			download $url "temporary.html"
			if [ $curlreturn -eq 0 ]
			then
				$imgurl_get
				$imgurl_filter
				rm -f temporary.html
				if [ -z $imgurl ]
				then
					if [ $pagenum -eq 1 ]
					then
						echo "All chapters (`expr $chapternum - 1`) downloaded"
						cd ..
						rmdir chapter-$chapternum
						rm -f temporary.html
						exit 0
					else
						echo "All pages (`expr $pagenum - 1`) of chapter #$chapternum downloaded"
						pagenum=1
						chapternum=`expr $chapternum + 1`
						curlreturn=1
					fi
				else
					if [ $pagenum -lt 100 ]
						then
						if [ $pagenum -lt 10 ]
						then
							download $imgurl "page-00$pagenum.jpg"
						else
							download $imgurl "page-0$pagenum.jpg"
						fi
					else
						download $imgurl "page-$pagenum.jpg"
					fi
					if [ $curlreturn -ne 0 ]
					then
						error_imgurl
					else
						echo "Page #$pagenum of chapter #$chapternum downloaded"
						pagenum=`expr $pagenum + 1`
					fi
				fi
			else
				echo "All pages (`expr $pagenum - 1`) of chapter #$chapternum downloaded"
				pagenum=1
				chapternum=`expr $chapternum + 1`
			fi
		done
		rm -f temporary.html
		cd ..
	done
}

function base_manga_manganame_vvolumenum_cchapternum_pagenum_html_downloader()
{
	mkdir -p $manganame
	cd $manganame

	while [ true ]
	do
		url="http://$base/manga/$manganame/v$volumenum/c$chapternum/$pagenum.html"
		rm -f temporary.html
		download $url "temporary.html"
		if [ $curlreturn -ne 0 ]
		then
			echo "All volumes (`expr $volumenum - 1`) downloaded"
			rm -f temporary.html
			exit 0
		fi
		mkdir -p volume-$volumenum
		cd volume-$volumenum
		while [ $curlreturn -eq 0 ]
		do
			url="http://$base/manga/$manganame/v$volumenum/c$chapternum/$pagenum.html"
			rm -f temporary.html
			download $url "temporary.html"
			if [ $curlreturn -ne 0 ]
			then
				echo "All chapters up to (`expr $chapternum - 1`) from volume $volumenum downloaded"
				rm -f temporary.html
				volumenum=`expr $volumenum + 1`
				if [ $volumenum -lt 10 ]
				then
					volumenum="0$volumenum"
				fi
			else
				mkdir -p chapter-$chapternum
				cd chapter-$chapternum
				while [ $curlreturn -eq 0 ]
				do
					url="http://$base/manga/$manganame/v$volumenum/c$chapternum/$pagenum.html"
					rm -f temporary.html
					download $url "temporary.html"
					if [ $curlreturn -eq 0 ]
					then
						$imgurl_get
						$imgurl_filter
						rm -f temporary.html
						if [ -z $imgurl ]
						then
							echo "All chapters (`expr $chapternum - 1`) downloaded"
							echo "All volumes ($volumenum) downloaded"
							cd ..
							rmdir chapter-$chapternum
							rm -f temporary.html
							cd ..
							rm -f temporary.html
							exit 0
						fi
						if [ $pagenum -lt 100 ]
							then
							if [ $pagenum -lt 10 ]
							then
								download $imgurl "page-00$pagenum.jpg"
							else
								download $imgurl "page-00$pagenum.jpg"
							fi
						else
							download $imgurl "page-00$pagenum.jpg"
						fi
						if [ $curlreturn -ne 0 ]
						then
							error_imgurl
						else
							echo "Page #$pagenum of chapter #$chapternum downloaded"
							pagenum=`expr $pagenum + 1`
						fi
					else
						echo "All pages (`expr $pagenum - 1`) of chapter #$chapternum downloaded"
						pagenum=1
						chapternum=`expr $chapternum + 1`
						if [ $chapternum -lt 100 ]
						then
							if [ $chapternum -lt 10 ]
							then
								chapternum="00$chapternum"
							else
								chapternum="0$chapternum"
							fi
						fi
					fi
				done
				curlreturn=0
				rm -f temporary.html
				cd ..
			fi
		done
		rm -f temporary.html
		cd ..
	done
}

function japscan_download_chapter()
{
	if [ ! -d `echo $subcategory` ]
	then
		mkdir `echo $subcategory`
	fi
	cd `echo $subcategory`
	echo "Downloading volume/chapter $subcategory"
	url="http://$base/lecture-en-ligne/$manganame/$subcategory/1.html"
	rm -f temporary2.html
	download $url "temporary2.html"
	nameid=`grep -E "<select" temporary2.html | grep -E "id\=\"mangas\"" | awk '{split($0,a,"data-nom=\"");print a[2]}' | cut -d \" -f 1`
	nameid=${nameid// /-}
	nameid=${nameid//---/-}
	if [ `grep -E "<select" temporary2.html | grep -E "id\=\"chapitres\"" | grep -E "data-nom" | wc -l` -eq 0 ]
	then
		subid=`grep -E "<select" temporary2.html | grep -E "id\=\"chapitres\"" | awk '{split($0,a,"data-uri=\"");print a[2]}' | cut -d \" -f 1`
	else
		subid=`grep -E "<select" temporary2.html | grep -E "id\=\"chapitres\"" | awk '{split($0,a,"data-nom=\"");print a[2]}' | cut -d \" -f 1`
	fi
	pagenum=1
	grep -E "<option" temporary2.html > temporary.html
	rm -f temporary2.html
	cat temporary.html | while read line
	do
		imgid=`echo $line | awk '{split($0,a,"data-img=\"");print a[2]}' | cut -d \" -f 1`
		if [[ $imgid == IMG__* ]]
		then
			imgurl="http://ww1.japscan.com/img/lels/$imgid"
		else
			imgurl="http://ww1.japscan.com/lel/$nameid/$subid/$imgid"
		fi
		download_image "$imgurl" "page.jpg"
		if [ $curlreturn -ne 0 ]
		then
			error_imgurl
		else
			if [ $pagenum -lt 100 ]
				then
				if [ $pagenum -lt 10 ]
				then
					mv "page.jpg" "page-00$pagenum.jpg"
				else
					mv "page.jpg" "page-0$pagenum.jpg"
				fi
			else
				mv "page.jpg" "page-$pagenum.jpg"
			fi
			echo "Page #$pagenum of chapter/volume #$subcategory downloaded"
			pagenum=`expr $pagenum + 1`
		fi
	done
	echo "All pages (`expr $pagenum - 1`) of chapter/volume #$subcategory downloaded"
	rm -f temporary.html
	cd ..
}

function mangahere_download_chapter()
{
	if [ $novolume -ne 1 ]
	then
		if [ ! -d `echo v$volumenum` ]
		then
			mkdir `echo v$volumenum`
		fi
		cd `echo v$volumenum`
	fi
	if [ ! -d `echo c$chapternum` ]
	then
		mkdir `echo c$chapternum`
	fi
	cd `echo c$chapternum`
	if [ $novolume -ne 1 ]
	then
		echo "Downloading chapter $chapternum of volume $volumenum"
	else
		echo "Downloading chapter $chapternum"
	fi
	curlreturn=0
	while [ $curlreturn -eq 0 ]
	do
		if [ $novolume -ne 1 ]
		then
			url="http://$base/manga/$manganame/v$volumenum/c$chapternum/$pagenum.html"
		else
			url="http://$base/manga/$manganame/c$chapternum/$pagenum.html"
		fi
		if [ $pagenum -eq 1 ]
		then
			url="`echo $url | rev | cut -d / -f 2- | rev`/"
		fi
		rm -f temporary.html
		download $url "temporary.html"
		notfound=`grep class=\"error_404\" temporary.html | wc -l`
		if [ ! -s temporary.html -o $notfound -ne 0 ]
		then
			curlreturn=1
		fi
		if [ $curlreturn -eq 0 ]
		then
			$imgurl_get
			$imgurl_filter
			rm -f temporary.html
			if [ -z $imgurl ]
			then
				rm -f temporary.html
			fi
			if [ $pagenum -lt 100 ]
				then
				if [ $pagenum -lt 10 ]
				then
					download_image $imgurl "page-00$pagenum.jpg"
				else
					download_image $imgurl "page-0$pagenum.jpg"
				fi
			else
				download_image $imgurl "page-$pagenum.jpg"
			fi
			if [ $curlreturn -ne 0 ]
			then
				error_imgurl
			else
				echo "Page #$pagenum of chapter #$chapternum downloaded"
				pagenum=`expr $pagenum + 1`
			fi
		else
			echo "All pages (`expr $pagenum - 1`) of chapter #$chapternum downloaded"
		fi
	done
	curlreturn=0
	rm -f temporary.html
	if [ $novolume -ne 1 ]
	then
		cd ../..
	else
		cd ..
	fi
}

function fanfox_download_chapter()
{
	if [ $novolume -ne 1 ]
	then
		if [ ! -d `echo v$volumenum` ]
		then
			mkdir `echo v$volumenum`
		fi
		cd `echo v$volumenum`
	fi
	if [ ! -d `echo c$chapternum` ]
	then
		mkdir `echo c$chapternum`
	fi
	cd `echo c$chapternum`
	if [ $novolume -ne 1 ]
	then
		echo "Downloading chapter $chapternum of volume $volumenum"
	else
		echo "Downloading chapter $chapternum"
	fi
	curlreturn=0
	while [ $curlreturn -eq 0 ]
	do
		if [ $novolume -ne 1 ]
		then
			url="http://$base/manga/$manganame/v$volumenum/c$chapternum/$pagenum.html"
		else
			url="http://$base/manga/$manganame/c$chapternum/$pagenum.html"
		fi
		rm -f temporary.html
		download $url "temporary.html"
		if [ ! -s temporary.html ]
		then
			curlreturn=1
		fi
		if [ $curlreturn -eq 0 ]
		then
			$imgurl_get
			$imgurl_filter
			rm -f temporary.html
			if [ -z $imgurl ]
			then
				rm -f temporary.html
			fi
			if [ $pagenum -lt 100 ]
				then
				if [ $pagenum -lt 10 ]
				then
					download_image $imgurl "page-00$pagenum.jpg"
				else
					download_image $imgurl "page-0$pagenum.jpg"
				fi
			else
				download_image $imgurl "page-$pagenum.jpg"
			fi
			if [ $curlreturn -ne 0 ]
			then
				error_imgurl
			else
				echo "Page #$pagenum of chapter #$chapternum downloaded"
				pagenum=`expr $pagenum + 1`
			fi
		else
			echo "All pages (`expr $pagenum - 1`) of chapter #$chapternum downloaded"
		fi
	done
	curlreturn=0
	rm -f temporary.html
	if [ $novolume -ne 1 ]
	then
		cd ../..
	else
		cd ..
	fi
}

function juinjutsuteam_download_chapter()
{
	if [ ! -d `echo v$volumenum` ]
	then
		mkdir `echo v$volumenum`
	fi
	cd `echo v$volumenum`
	if [ ! -d `echo c$chapternum` ]
	then
		mkdir `echo c$chapternum`
	fi
	cd `echo c$chapternum`
	echo "Downloading chapter $chapternum of volume $volumenum"
	curlreturn=0
	while [ $curlreturn -eq 0 ]
	do
		url="http://$base/read/$manganame/$lang/$volumenum/$chapternum/page/$pagenum"
		rm -f temporary.html
		download $url "temporary.html"
		if [ ! -s temporary.html ]
		then
			curlreturn=1
		fi
		if [ $curlreturn -eq 0 ]
		then
			$imgurl_get
			rm -f temporary.html
			if [ -z $imgurl ]
			then
				rm -f temporary.html
			fi
			if [ $pagenum -lt 100 ]
				then
				if [ $pagenum -lt 10 ]
				then
					download $imgurl "page-00$pagenum.jpg"
				else
					download $imgurl "page-0$pagenum.jpg"
				fi
			else
				download $imgurl "page-$pagenum.jpg"
			fi
			if [ $curlreturn -ne 0 ]
			then
				error_imgurl
			else
				echo "Page #$pagenum of chapter #$chapternum downloaded"
				pagenum=`expr $pagenum + 1`
			fi
		else
			echo "All pages (`expr $pagenum - 1`) of chapter #$chapternum downloaded"
		fi
	done
	curlreturn=0
	rm -f temporary.html
	cd ../..
}

url=$1
if [ ! $url ]
then
	echo "Usage: $0 URL"
else
	if [ ! `echo $url | grep -E ^https?://` ]
	then
		url="http://$url"
	fi

	base=`echo $url | cut -d / -f 3`
	case $base in
	"www.mangareader.net" | "www.mangapanda.com")
		imgurl_get="imgurl_firstimgtag"
		imgurl_filter="imgurl_filter_manganame"
		site=`echo $base | cut -d . -f 2`
		tld=`echo $base | cut -d . -f 3`
		if [ `echo $url | grep -E ^https?://www\.$site\.$tld/[0-9]*-[0-9]*-[0-9]*/[^/]*/chapter-[0-9]*\.html` ]
		then
			manganame=`echo $url | cut -d / -f 5`
			chapternum=`echo $url | cut -d / -f 6 | cut -d - -f 2 | cut -d . -f 1`
			pagenum=`echo $url | cut -d / -f 4 | cut -d - -f 3`
		elif [ `echo $url | grep -E ^https?://www\.$site\.$tld/[0-9]*/[^/]*.html` ]
		then
			manganame=`echo $url | cut -d / -f 5 | awk '{split($0,a,".html");$1=a[1];print $1}'`
			chapternum=1
			pagenum=1
		elif [ `echo $url | grep -E ^https?://www\.$site\.$tld/[^/]*/[0-9]*/[0-9]*` ]
		then
			manganame=`echo $url | cut -d / -f 4`
			chapternum=`echo $url | cut -d / -f 5`
			pagenum=`echo $url | cut -d / -f 6`
		elif [ `echo $url | grep -E ^https?://www\.$site\.$tld/[^/]*/[0-9]*` ]
		then
			manganame=`echo $url | cut -d / -f 4`
			chapternum=`echo $url | cut -d / -f 5`
			pagenum=1
		elif [ `echo $url | grep -E ^https?://www\.$site\.$tld/[^/]*` ]
		then
			manganame=`echo $url | cut -d / -f 4`
			chapternum=1
			pagenum=1
		else
			error_url
		fi
		base_manganame_chapternum_pagenum_downloader
		;;
	"fanfox.net")
		imgurl_get="imgurl_firstimgtag"
		imgurl_filter="imgurl_filter_firstresult"
		if [ `echo $url | grep -E ^https?://fanfox\.net/manga/[^/]*/c[^/]*/[0-9]*\.html` ]
		then
			manganame=`echo $url | cut -d / -f 5`
			mkdir -p $manganame
			cd $manganame
			chapternum=`echo $url | cut -d / -f 6 | cut -d c -f 2`
			found=0
		elif [ `echo $url | grep -E ^https?://fanfox\.net/manga/[^/]*/v[^/]*/c[^/]*/[0-9]*\.html` ]
		then
			manganame=`echo $url | cut -d / -f 5`
			mkdir -p $manganame
			cd $manganame
			volumenum=`echo $url | cut -d / -f 6 | cut -d v -f 2`
			chapternum=`echo $url | cut -d / -f 7 | cut -d c -f 2`
			found=0
		elif [ `echo $url | grep -E ^https?://fanfox\.net/manga/[^/]*` ]
		then
			manganame=`echo $url | cut -d / -f 5`
			mkdir -p $manganame
			cd $manganame
			found=1
		else
			error_url
		fi
		echo "Retrieving URL list..."
		rm -f temporary.html
		download "`echo $url | cut -d / -f 1-5`" "temporary.html"
		echo "done"
		echo "Catching up to desired chapter..."
		grep -E href\=\"//fanfox\.net/manga/[^/]*/?v?[^/]*/c[^/]*/[0-9]*\.html\" temporary.html > temporary2.html
		cut -d \" -f 2 temporary2.html > temporary.html
		rm -f temporary2.html
		for word in `tac_awk temporary.html`
		do
			if [ $found -ne 1 ]
			then
				if [ `echo $word | grep -E //fanfox\.net/manga/[^/]*/?v?$volumenum/c$chapternum/[0-9]*\.html` ]
				then
					found=1
				fi
			fi
			if [ $found -eq 1 ]
			then
				novolume=0
				url=`echo $word | cut -d \" -f 2 | cut -d \" -f 1`
				if [ `echo $url | grep -E //fanfox\.net/manga/[^/]*/c[^/]*/[0-9]*\.html` ]
				then
					novolume=1
					chapternum=`echo $url | cut -d / -f 6 | cut -d c -f 2`
					pagenum=`echo $url | cut -d / -f 7 | cut -d . -f 1`
				else
					volumenum=`echo $url | cut -d / -f 6 | cut -d v -f 2`
					chapternum=`echo $url | cut -d / -f 7 | cut -d c -f 2`
					pagenum=`echo $url | cut -d / -f 8 | cut -d . -f 1`
				fi
				fanfox_download_chapter
			fi
		done
		rm -f temporary.html
		;;
	"www.mangahere.co")
		imgurl_get="imgurl_firstimgtag"
		imgurl_filter="imgurl_filter_secondresult"
		if [ `echo $url | grep -E ^https?://www\.mangahere\.co/manga/[^/]*/c[^/]*` ]
		then
			manganame=`echo $url | cut -d / -f 5`
			mkdir -p $manganame
			cd $manganame
			chapternum=`echo $url | cut -d / -f 6 | cut -d c -f 2`
			found=0
		elif [ `echo $url | grep -E ^https?://www\.mangahere\.co/manga/[^/]*/v[^/]*/c[^/]*` ]
		then
			manganame=`echo $url | cut -d / -f 5`
			mkdir -p $manganame
			cd $manganame
			volumenum=`echo $url | cut -d / -f 6 | cut -d v -f 2`
			chapternum=`echo $url | cut -d / -f 7 | cut -d c -f 2`
			found=0
		elif [ `echo $url | grep -E ^https?://www\.mangahere.co/manga/[^/]*` ]
		then
			manganame=`echo $url | cut -d / -f 5`
			mkdir -p $manganame
			cd $manganame
			found=1
		else
			error_url
		fi
		echo "Retrieving URL list..."
		rm -f temporary.html
		download "`echo $url | cut -d / -f 1-5`/" "temporary.html"
		echo "done"
		echo "Catching up to desired chapter..."
		grep -v \<label\>Status\: temporary.html |
		grep -E href\=\"//www\.mangahere\.co/manga/$manganame/?v?[^/]*/c[^/]*/\" > temporary2.html
		cat temporary2.html | awk '{split($0,a,"href");$1=a[2];print $1}' | awk '{split($0,a,"\"");$1=a[2];print $1"1.html"}' > temporary.html
		rm -f temporary2.html
		for word in `tac_awk temporary.html`
		do
			if [ $found -ne 1 ]
			then
				if [ `echo $word | grep -E //www\.mangahere\.co/manga/[^/]*/?v?$volumenum/c$chapternum` ]
				then
					found=1
				fi
			fi
			if [ $found -eq 1 ]
			then
				novolume=0
				pagenum=1
				url=`echo $word | cut -d \" -f 2 | cut -d \" -f 1`
				if [ `echo $url | grep -E //www\.mangahere\.co/manga/[^/]*/c[^/]*` ]
				then
					novolume=1
					chapternum=`echo $url | cut -d / -f 6 | cut -d c -f 2`
				else
					volumenum=`echo $url | cut -d / -f 6 | cut -d v -f 2`
					chapternum=`echo $url | cut -d / -f 7 | cut -d c -f 2`
				fi
				mangahere_download_chapter
			fi
		done
		rm -f temporary.html
		;;
	"www.japscan.com")
		if [ `echo $url | grep -E ^https?://www\.japscan\.com/lecture-en-ligne/[^/]*/[^/]*/` ]
		then
			manganame=`echo $url | cut -d / -f 5`
			mkdir -p $manganame
			cd $manganame
			subcategory=`echo $url | cut -d / -f 6`
			found=0
		elif [ `echo $url | grep -E ^https?://www\.japscan\.com/mangas/[^/]*/` ]
		then
			manganame=`echo $url | cut -d / -f 5`
			mkdir -p $manganame
			cd $manganame
			found=1
		else
			error_url
		fi
		echo "Retrieving URL list..."
		rm -f temporary2.html
		download "`echo $url | cut -d / -f 1-3`/mangas/$manganame/" "temporary2.html"
		sed 's/<a/\
<a/g' temporary2.html > temporary.html
		echo "done"
		echo "Catching up to desired chapter..."
		grep -E href\=\"//www\.japscan\.com/lecture-en-ligne/$manganame/[^/]*/\" temporary.html > temporary2.html
		cat temporary2.html | awk '{split($0,a,"href");$1=a[2];print $1}' | awk '{split($0,a,"\"");$1=a[2];print "http:"$1"1.html"}' > temporary.html
		rm -f temporary2.html
		for word in `tac_awk temporary.html`
		do
			if [ $found -ne 1 ]
			then
				if [ `echo $word | grep -E https?://www\.japscan\.com/lecture-en-ligne/[^/]*/$subcategory/[0-9]*\.html` ]
				then
					found=1
				fi
			fi
			if [ $found -eq 1 ]
			then
				url=`echo $word | cut -d \" -f 2 | cut -d \" -f 1`
				subcategory=`echo $url | cut -d / -f 6`
				japscan_download_chapter
			fi
		done
		rm -f temporary.html
		;;
	"juinjutsuteam.netsons.org")
		imgurl_get="imgurl_firstimgtag_class_open"
		if [ `echo $url | grep -E ^https?://juinjutsuteam\.netsons\.org/read/[^/]*/[^/]*/[0-9]*/[0-9]*` ]
		then
			manganame=`echo $url | cut -d / -f 5`
			mkdir -p $manganame
			cd $manganame
			lang=`echo $url | cut -d / -f 6`
			volumenum=`echo $url | cut -d / -f 7`
			chapternum=`echo $url | cut -d / -f 8`
			found=0
		elif [ `echo $url | grep -E ^https?://juinjutsuteam\.netsons\.org/series/[^/]]*` ]
		then
			manganame=`echo $url | cut -d / -f 5`
			mkdir -p $manganame
			cd $manganame
			found=1
		else
			error_url
		fi
		echo "Retrieving URL list..."
		rm -f temporary.html
		download "http://juinjutsuteam.netsons.org/series/$manganame" "temporary.html"
		echo "done"
		echo "Catching up to desired chapter..."
		grep -E href\=\"https?://juinjutsuteam\.netsons\.org/read/[^/]*/[^/]*/[0-9]*/[0-9]*/\" temporary.html > temporary2.html
		cut -d \" -f 4 temporary2.html > temporary.html
		rm -f temporary2.html
		for word in `tac_awk temporary.html`
		do
			if [ $found -ne 1 ]
			then
				if [ `echo $word | grep -E https?://juinjutsuteam\.netsons\.org/read/$manganame/$lang/$volumenum/$chapternum` ]
				then
					found=1
				fi
			fi
			if [ $found -eq 1 ]
			then
				url=`echo $word | cut -d \" -f 2 | cut -d \" -f 1`
				lang=`echo $url | cut -d / -f 6`
				volumenum=`echo $url | cut -d / -f 7`
				chapternum=`echo $url | cut -d / -f 8`
				pagenum=1
				juinjutsuteam_download_chapter
			fi
		done
		rm -f temporary.html
	esac
fi
