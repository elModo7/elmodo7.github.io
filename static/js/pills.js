var pillsPage = 0;

function pillsEvents(){
	unbindEvents();
	var itemsPerRow = 4;
	itemsPerPage = 12;
	var pillsHTML = '';
	var cntKeys = 0;
	for (const [key, value] of Object.entries(pills.slice(pillsPage * itemsPerPage, pillsPage * itemsPerPage + itemsPerPage))) {
		if(cntKeys == itemsPerPage){
			break;
		}
		if(key % itemsPerRow == 0){
			if(pillsHTML == ""){
				pillsHTML += '<div class="row mt-4">';
			}else{
				pillsHTML += '</div><div class="row mt-4">';
			}
		}
		pillsHTML += '<div class="col-sm-3">';
		for (const [keyBadge, valueBadge] of Object.entries(value.badges)) {
			pillsHTML +=	'<span class="badge ' + valueBadge.color + '">' + valueBadge.name + '</span> ';
		}
		pillsHTML += '<span class="badge"> </span>'; // Needed for frame possition
		pillsHTML += '<a ' + (value.url == '' ? '' : ('href="' + value.url + '" target="_blank"')) + ' class="link article-link" article="' + value.page + '" title="' + value.title + '" description="' + value.description + '"><div class="position-relative">';
		pillsHTML += '<div class="article-image column"><div><figure><img src="' + value.img + '" alt="Photo 1" class="img-fluid article-image"></figure></div></div>';
		if(value.ribbon.color && value.ribbon.name){
			pillsHTML +=	'<div class="ribbon-wrapper ribbon-lg">';
			pillsHTML +=	'<div class="ribbon ' + value.ribbon.color + ' text-lg">' + value.ribbon.name + '</div></div>';
		}
		pillsHTML += '<h3 style="text-align:center">' + value.title + '</h3><p style="text-align:center">' + value.description + '</p></div></a></div>';
		if((key + 1) % itemsPerRow == 0 || cntKeys + 1 == itemsPerPage || cntKeys + 1 == pills.length){
			pillsHTML += '</div>';
		}
		cntKeys++;
	}
	
	if(pills.length > itemsPerPage){
		pillsHTML += '<br><br><div class="row col-sm-12"><div class="col-sm-12 col-md-12 d-flex justify-content-center"><div class="dataTables_paginate paging_simple_numbers" id="example2_paginate"><ul class="pagination">';
		pillsHTML += '<li class="paginate_button page-item previous ' + (pillsPage == 0 ? 'disabled' : '') + '" id="example2_previous"><a href="#" aria-controls="example2" data-dt-idx="' + pillsPage + '" tabindex="0" class="page-link">Previous</a></li>';
		
		var info = numPagesToShowInPagination(parseInt(pillsPage) + 1, pillsTotalPages);
		for (const [key, value] of Object.entries(info.pages)) {
			pillsHTML +=	'<li class="paginate_button page-item ' + ((parseInt(key) + 1 == info.activePageIndex) ? 'active' : '') + '"><a href="#" aria-controls="example2" data-dt-idx="' + value + '" tabindex="0" class="page-link">' + value + '</a></li>';
		}

		pillsHTML += '<li class="paginate_button page-item next ' + ((parseInt(pillsPage) + 1 == pillsTotalPages) ? 'disabled' : '') + '" id="example2_next"><a href="#" aria-controls="example2" data-dt-idx="' + parseInt(parseInt(pillsPage) + 2) + '" tabindex="0" class="page-link">Next</a></li></ul></div></div></div>';
	}
	
	$("#body_pills").html(pillsHTML);
	loadBreadcrumbEvents();
	bindPillsPagination();
	bindArticles(); // Important after pagination
}

function bindPillsPagination(){
	$(".page-link").click(function(){
		event.preventDefault();
		pillsPage = parseInt($(this).attr("data-dt-idx")) - 1;
		pillsEvents();
		animateToTop();
	});
}