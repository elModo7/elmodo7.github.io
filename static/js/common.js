function numPagesToShowInPagination(curPage, totalPages) {
    // Pagination allows max 7 pages ex: [Prev 1, 2, 3, 4, 5, 6, 7 Next]
    const maxPagesToShow = 5;
    let startPage, endPage;

    if (totalPages <= maxPagesToShow) {
        // Less than or equal to maxPagesToShow, show all pages
        startPage = 1;
        endPage = totalPages;
    } else {
        if (curPage <= Math.ceil(maxPagesToShow / 2)) {
            // Near the start
            startPage = 1;
            endPage = maxPagesToShow;
        } else if (curPage + Math.floor(maxPagesToShow / 2) >= totalPages) {
            // Near the end
            startPage = totalPages - maxPagesToShow + 1;
            endPage = totalPages;
        } else {
            // Somewhere in the middle
            startPage = curPage - Math.floor(maxPagesToShow / 2);
            endPage = curPage + Math.floor(maxPagesToShow / 2);
        }
    }

    // Create the pages array
    const pages = Array.from({
        length: (endPage - startPage + 1)
    }, (_, i) => startPage + i);

    // Determine the active page index within the displayed pages
    let activePageIndex = pages.indexOf(curPage) + 1; // +1 to make it 1-based

    return {
        pages,
        activePageIndex
    };
}

function unbindEvents(){
	$(".page-link").unbind(); // Pagination
	$(".article-link").unbind(); // Articles
}

function bindArticles(){
	$(".article-link").click(function(){
		if($(this).attr('href') === undefined) { 
			var articlePath = $(this).attr("article");
			var articleTitle = $(this).attr("title");
			var articleDescription = $(this).attr("description");
			$("#divMainContent").load("common/article.html", function(){
				$("#article_title").html(articleTitle);
				$("#article_title_description").html(articleDescription);
				removeBreadcrumbClasses();
				if(currentMenuTab == "about_me"){
					$("#article_breadcrumb_menu").addClass("goAboutMe");
					$("#article_breadcrumb_menu").html("About me");
				}else if(currentMenuTab == "work_projects"){
					$("#article_breadcrumb_menu").addClass("goWorkProjects");
					$("#article_breadcrumb_menu").html("Work projects");
				}else if(currentMenuTab == "personal_projects"){
					$("#article_breadcrumb_menu").addClass("goPersonalProjects");
					$("#article_breadcrumb_menu").html("Personal projects");
				}else if(currentMenuTab == "pills"){
					$("#article_breadcrumb_menu").addClass("goPills");
					$("#article_breadcrumb_menu").html("Pills & Code Snippets");
				}
				$("#article_breadcrumb").html(articleTitle);
				
				loadBreadcrumbEvents();
				$("#article_body").load(articlePath, function(){
					loadJS("static/js/prism.js", true);
				});
			});
		}
	});
}

function loadBreadcrumbEvents(){
	$(".goAboutMe").unbind();
	$(".goAboutMe").click(function(){
		goAboutMe();
	});
	
	$(".goWorkProjects").unbind();
	$(".goWorkProjects").click(function(){
		goWorkProjects();
	});
	
	$(".goPersonalProjects").unbind();
	$(".goPersonalProjects").click(function(){
		goPersonalProjects();
	});
	
	$(".goPills").unbind();
	$(".goPills").click(function(){
		goPills();
	});
}

function removeBreadcrumbClasses(){
	$("#article_breadcrumb_menu").removeClass("goAboutMe");
	$("#article_breadcrumb_menu").removeClass("goWorkProjects");
	$("#article_breadcrumb_menu").removeClass("goPersonalProjects");
	$("#article_breadcrumb_menu").removeClass("goPills");
}

function loadJS(FILE_URL, async = true) {
  let scriptEle = document.createElement("script");

  scriptEle.setAttribute("src", FILE_URL);
  scriptEle.setAttribute("type", "text/javascript");
  scriptEle.setAttribute("async", async);

  document.body.appendChild(scriptEle);

  // success event 
  scriptEle.addEventListener("load", () => {
    console.log("File loaded")
  });
   // error event
  scriptEle.addEventListener("error", (ev) => {
    console.log("Error on loading file", ev);
  });
}