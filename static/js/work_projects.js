var workProjectsPage = 0;

function workProjectsEvents(){
	unbindPagination();
	var itemsPerRow = 3;
	itemsPerPage = 9;
	var workProjectsHTML = '';
	var cntKeys = 0;
	for (const [key, value] of Object.entries(workProjects.slice(workProjectsPage * itemsPerPage, workProjectsPage * itemsPerPage + itemsPerPage))) {
		if(cntKeys == itemsPerPage){
			break;
		}
		if(key % itemsPerRow == 0){
			workProjectsHTML += '<div class="row mt-4">';
		}
		workProjectsHTML += '<div class="col-sm-4">';
		for (const [keyBadge, valueBadge] of Object.entries(value.badges)) {
			workProjectsHTML +=	'<span class="badge ' + valueBadge.color + '">' + valueBadge.name + '</span> ';
		}
		workProjectsHTML += '<span class="badge"> </span>'; // Needed for frame possition
		workProjectsHTML += '<a href="' + value.url + '" class="link"><div class="position-relative">';
		workProjectsHTML +=	'<img src="static/img/sample.png" alt="Photo 1" class="img-fluid">';
		if(value.ribbon.color && value.ribbon.name){
			workProjectsHTML +=	'<div class="ribbon-wrapper ribbon-lg">';
			workProjectsHTML +=	'<div class="ribbon ' + value.ribbon.color + ' text-lg">' + value.ribbon.name + '</div></div>';
		}
		workProjectsHTML += '<h3 style="text-align:center">' + value.title + '</h3><p style="text-align:center">' + value.description + '</p></div></a></div>';
		if((key + 1) % itemsPerRow == 0 || cntKeys + 1 == itemsPerPage || cntKeys + 1 == workProjects.length){
			workProjectsHTML += '</div>';
		}
		cntKeys++;
	}
	
	if(workProjects.length > itemsPerPage){
		workProjectsHTML += '<div class="row col-sm-12"><div class="col-sm-12 col-md-12 d-flex justify-content-center"><div class="dataTables_paginate paging_simple_numbers" id="example2_paginate"><ul class="pagination">';
		workProjectsHTML += '<li class="paginate_button page-item previous ' + (workProjectsPage == 0 ? 'disabled' : '') + '" id="example2_previous"><a href="#" aria-controls="example2" data-dt-idx="' + workProjectsPage + '" tabindex="0" class="page-link">Previous</a></li>';
		
		var info = numPagesToShowInPagination(parseInt(workProjectsPage) + 1, workProjectsTotalPages);
		for (const [key, value] of Object.entries(info.pages)) {
			workProjectsHTML +=	'<li class="paginate_button page-item ' + ((parseInt(key) + 1 == info.activePageIndex) ? 'active' : '') + '"><a href="#" aria-controls="example2" data-dt-idx="' + value + '" tabindex="0" class="page-link">' + value + '</a></li>';
		}

		workProjectsHTML += '<li class="paginate_button page-item next ' + ((parseInt(workProjectsPage) + 1 == workProjectsTotalPages) ? 'disabled' : '') + '" id="example2_next"><a href="#" aria-controls="example2" data-dt-idx="' + parseInt(parseInt(workProjectsPage) + 2) + '" tabindex="0" class="page-link">Next</a></li></ul></div></div></div>';
	}
	
	$("#body_work_projects").html(workProjectsHTML);
	loadAboutMeEvent();
	bindWorkProjectsPagination();
}

function bindWorkProjectsPagination(){
	$(".page-link").click(function(){
		event.preventDefault();
		workProjectsPage = parseInt($(this).attr("data-dt-idx")) - 1;
		workProjectsEvents();
	});
}