$(document).ready(function () {
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
		
	$("#divMainContent").load("about.html");
		
	document.getElementById("year_footer").innerHTML = new Date().getFullYear();
});

function goAboutMe(){
	currentMenuTab = "about_me";
	$(".nav-link").removeClass("active");
	$("#btn_about").addClass("active");
	$("#divMainContent").load("about.html");
}

function goWorkProjects(){
	currentMenuTab = "work_projects";
	$(".nav-link").removeClass("active");
	$("#btn_work_projects").addClass("active");
	$("#divMainContent").load("work_projects.html", function(){
		workProjectsEvents();
	});
}

function goPersonalProjects(){
	currentMenuTab = "personal_projects";
	$(".nav-link").removeClass("active");
	$("#btn_personal_projects").addClass("active");
	$("#divMainContent").load("personal_projects.html", function(){
		personalProjectsEvents();
	});
}

function goPills(){
	currentMenuTab = "pills";
	$(".nav-link").removeClass("active");
	$("#btn_pills").addClass("active");
	$("#divMainContent").load("pills.html", function(){
		pillsEvents();
	});
}