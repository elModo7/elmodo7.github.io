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
			if(articlePath != "undefined" && articlePath != ""){
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
					}else if(currentMenuTab == "upcoming_content"){
						$("#article_breadcrumb_menu").addClass("goUpcomingContent");
						$("#article_breadcrumb_menu").html("Upcoming Content");
					}
					loadBreadcrumbEvents();
					
					$("#article_breadcrumb").html(articleTitle);
					$("#article_body").load(articlePath, function(responseText, textStatus, XMLHttpRequest){
						loadJS("static/js/prism.js", true);
						if(textStatus == "error"){
							$("#article_breadcrumb").html("Under construction!");
							$("#article_body").load("common/under_construction.html", function(responseText, textStatus, XMLHttpRequest){
								$("#article_title").html("Ooops, there is no more info about this article yet!");
								$("#article_title_description").html("This is probably due to me adding the article to the list before making a page for it.<br>If you want more <i>information about this specific topic</i>, you can always <a class='text-danger' href='mailto:martinez.picardo.victor@gmail.com' target='_blank' onclick='copyMail()'>contact me <i class='fas fa-envelope'></i></a> to fill in this article.");
								$("#article_title_description").append('<br>I am also available for <span class="text-warning">real time feedback about it on </span><a class="text-primary" href="https://discord.gg/stu2vkJ" target="_blank">Discord <i class="fab fa-discord"></i></a>.');
								$("#article_title_description").append('<br>And you can also find me on <a class="text-info" href="https://t.me/victor_smp" target="_blank">Telegram <i class="fab fa-telegram-plane"></i></a>.');
							});
						}
						animateToTop();
					});
				});
			}else{
				// Article has no defined page nor url attached, do nothing (sometimes I may want to show a preview in the list of projects but not necessarily create a whole article for it, this is specially the case with most work projects where I can not disclose much info about them via public articles, but I am fond of asking questions in interviews)
			}
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
	})	;
	
	$(".goPills").unbind();
	$(".goPills").click(function(){
		goPills();
	});
	
	$(".goUpcomingContent").unbind();
	$(".goUpcomingContent").click(function(){
		goUpcomingContent();
	});
}

function removeBreadcrumbClasses(){
	$("#article_breadcrumb_menu").removeClass("goAboutMe");
	$("#article_breadcrumb_menu").removeClass("goWorkProjects");
	$("#article_breadcrumb_menu").removeClass("goPersonalProjects");
	$("#article_breadcrumb_menu").removeClass("goPills");
	$("#article_breadcrumb_menu").removeClass("goUpcomingContent");
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

function animateToTop(){
	$("html, body").animate({ scrollTop: 0 }, "slow");
}

function copyMail(){
	navigator.clipboard.writeText("martinez.picardo.victor@gmail.com");

	toastr.options = {
	  "closeButton": false,
	  "debug": false,
	  "newestOnTop": false,
	  "progressBar": false,
	  "positionClass": "toast-top-center",
	  "preventDuplicates": false,
	  "onclick": null,
	  "showDuration": "300",
	  "hideDuration": "1000",
	  "timeOut": "5000",
	  "extendedTimeOut": "1000",
	  "showEasing": "swing",
	  "hideEasing": "linear",
	  "showMethod": "fadeIn",
	  "hideMethod": "fadeOut"
	}
	toastr["success"]("martinez.picardo.victor@gmail.com", "Copied to Clipboard")
	//toastr.success('Mail copied to the clipboard!', 'Copied');
}