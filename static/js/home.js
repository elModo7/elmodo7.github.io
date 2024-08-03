$(document).ready(function () {
	let searchParams = new URLSearchParams(window.location.search);
	$("#header").load("common/header.html"); 
	$("#menu").load("common/menu.html", function(){
		$("#btn_about").click(function(){
			event.preventDefault();
			goAboutMe();
		});
		
		$("#btn_work_projects").click(function(){
			event.preventDefault();
			goWorkProjects();
		});
		
		$("#btn_personal_projects").click(function(){
			event.preventDefault();
			goPersonalProjects();
		});
		
		$("#btn_pills").click(function(){
			event.preventDefault();
			goPills();
		});
	});
	
	if(!searchParams.has("article")){
		$("#divMainContent").load("about.html", function(){
			loadBreadcrumbEvents();
		});
	}else{
		// Allow for direct article -> http://localhost/?article=/pills/wireshark_vnc_capture.html&title=Wireshark%20VNC%20Capture
		var articlePath = searchParams.get("article");
		var articleTitle = searchParams.get("title");
		var articleDescription = searchParams.get("description");
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
			
			loadBreadcrumbEvents();
			if(articlePath != "undefined" && articlePath != ""){
				$("#article_breadcrumb").html(articleTitle);
				$("#article_body").load(articlePath, function(){
					loadJS("static/js/prism.js", true);
				});
			}else{
				$("#article_breadcrumb").html("Under construction!");
				$("#article_body").load("common/under_construction.html", function(){
					$("#article_title").html("Ooops, there is no more info about this article yet!");
					$("#article_title_description").html("This is probably due to me adding the article to the list before making a page for it.<br>If you want more <i>information about this specific topic</i>, you can always <a class='text-danger' href='mailto:martinez.picardo.victor@gmail.com' target='_blank'>contact me <i class='fas fa-envelope'></i></a> to fill in this article.");
					$("#article_title_description").append('<br>I am also available for <span class="text-warning">real time feedback about it on </span><a class="text-primary" href="https://discord.gg/stu2vkJ" target="_blank">Discord <i class="fab fa-discord"></i></a>.');
					$("#article_title_description").append('<br>And you can also find me on <a class="text-info" href="https://t.me/victor_smp" target="_blank">Telegram <i class="fab fa-telegram-plane"></i></a>.');
				});
			}
		});
	}
	
	if(isMobile){
		$(".sidebar-mini").addClass("sidebar-collapse");
	}else{
		$(".sidebar-mini").removeClass("sidebar-collapse");
	}
		
	document.getElementById("year_footer").innerHTML = new Date().getFullYear();
});

function goAboutMe(){
	event.preventDefault();
	currentMenuTab = "about_me";
	$(".nav-link").removeClass("active");
	$("#btn_about").addClass("active");
	$("#divMainContent").load("about.html", function(){
		loadBreadcrumbEvents();
	});
}

function goWorkProjects(){
	event.preventDefault();
	currentMenuTab = "work_projects";
	$(".nav-link").removeClass("active");
	$("#btn_work_projects").addClass("active");
	$("#divMainContent").load("work_projects.html", function(){
		workProjectsEvents();
	});
}

function goPersonalProjects(){
	event.preventDefault();
	currentMenuTab = "personal_projects";
	$(".nav-link").removeClass("active");
	$("#btn_personal_projects").addClass("active");
	$("#divMainContent").load("personal_projects.html", function(){
		personalProjectsEvents();
	});
}

function goPills(){
	event.preventDefault();
	currentMenuTab = "pills";
	$(".nav-link").removeClass("active");
	$("#btn_pills").addClass("active");
	$("#divMainContent").load("pills.html", function(){
		pillsEvents();
	});
}