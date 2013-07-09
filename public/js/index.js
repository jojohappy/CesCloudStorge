// 统一命名空间储存全局变量
var _GLOBE_DATA = (function() {
	var data = {
		hoverFolderId:'',
		folderTreeTempHtml:'',
		copyFileSelectedfolderId:'',
		hoverfileId:''
	};
	// 闭包返回
	return function(key, val) {
		// getter
		if (val === undefined) { 
			return data[key];
		}
		// setter
		else { 
			return data[key] = val;
		}
	}
})();

Function.prototype.method= function(name,func){
	this.prototype[name] = func;
};

Array.method('isArray',function(){
	return true;
});

$(document).ready(function(){
	init();
	initDomEvent();
	initDomSize();  
});

$(window).resize(function () {
	// 设置元素高度
    initDomSize();
});		

var init = function(){
	getFileList('-1');
	$('#navbarUserName').html('admin');
	$('#ulJumbotronPath .hiddenLiPath').hide();
	$.ajax({
		url:'http://172.17.10.61:8081/list/folders',
		data:{
			randomQuery: (new Date()).getTime()
		},
		success:function(data){
			var tempObj = data.folderlist;
			traversal(tempObj,0);
			initTraversalEvent();
		},
		error:function(errorThrown){
		
		}
	});
	
	/*
	$.ajax({
		url:'http://172.17.10.61:8081/user/login',
		data:{
			username:'user1@ce-service.com.cn',
			password:'111111',
			randomQuery: (new Date()).getTime()
		},
		success:function(data){
			if('success'===data.result){
				
				//getFileList();
			}else{
				alert('登录失败');
			}
		},
		error:function(errorThrown){
		
		}
	});
	*/
};

var initDomEvent = function(){
	$('#navbarUserName').bind('mouseover',function(){
		$(this).animate({
			marginLeft:'-120px'
		},{});
	});

	$('#aLogoutBtn').bind('mouseout',function(){
		$('#navbarUserName').animate({
			marginLeft:'0px'
		},{});
	});
	
	$('#aMyDiskFolderPath').bind('click',function(){
		getFileList($(this).attr('folderId'));
	});
	
	$('#aLastFolderPath').bind('click',function(){
		getFileList($(this).attr('folderId'));
	});
	
	$('#divFileTitle .title-file').bind('mouseover',function(){
		$(this).css('color','rgb(0, 136, 204)');
	});
	
	$('#divFileTitle .title-file').bind('mouseout',function(){
		$(this).css('color','rgb(51, 51, 51)');
	});
	
	$('#copyFileConfirm').bind('click',function(){
		
		$.ajax({
			url:'http://172.17.10.61:8081/file/copy',
			type:'POST',
			data:{
				file_id:_GLOBE_DATA('hoverfileId'),
				dest_folder_id:_GLOBE_DATA('copyFileSelectedfolderId'),
				randomQuery: (new Date()).getTime()
			},
			success:function(data){
				$('#copyFileCancle').trigger('click');
				$('#noticeText').html('复制文件成功！');
				$('#notice').modal('show');
			},
			error:function(errorThrown){
			
			}
		});
	
		
	});
};

var initDomSize = function(){
	$('#ulFile').height($(document.body)[0].clientHeight-200);
	$('#divFileCover').height($(document.body)[0].clientHeight-76).css('left',($(document.body)[0].clientWidth-940)/2);
	$('#folderTreeForCopyFile').css('padding-left',($('#folderTreeForCopyFile').width()/2-150)+'px');
};

var getFileList = function(folderId){
	$('#divFileCover').show();
	$.ajax({
		url:'http://172.17.10.61:8081/list/files',
		data:{
			folder_id:folderId,
			randomQuery: (new Date()).getTime()
		},
		success:function(data){
			createFileListDom(data.filelist,data.folderlist);
		},
		error:function(errorThrown){
		
		}
	});
	
};

var createFileListDom = function(fileList,folderlist){
	var tempHtml='';
	for(var i = 0; i<fileList.length;i++){
		tempHtml = tempHtml
		+'<li class="'+((0===i%2)?'li-background-blue':'')+'" folderId='+fileList[i].folder_id+'" fileId='+fileList[i].file_id+'>'
			+'<div class="div-file-checkbox" id="">'
				+'<input type="checkbox" name="" />'
			+'</div>'
			+'<div class="div-file-icon" id="">'
				+'<img src="./img/icon/icon-'+((''===fileList[i].mime_type)?'folder':fileList[i].mime_type)+'.png" class="img-file-icon"/>'
			+'</div>'
			+'<div class="div-file-name-action" id="">'
				+'<div class="div-file-name" id=""><span class="span-file-name">'+fileList[i].name+'</span></div>'
				+'<div class="div-file-action hidden" id="">'
					+((''===fileList[i].mime_type)?'':'<button class="btn btn-info btn-mini btn-file-action" type="button">下载</button>')
					+'<button class="btn btn-mini btn-file-action" type="button">移动</button>'
					+((''===fileList[i].mime_type)?'':'<a href="#copyModal" role="button" class="btn btn-mini btn-file-action" type="button" data-toggle="modal">复制</a>')
					+'<button class="btn btn-mini btn-file-action" type="button">重命名</button>'
					+'<button class="btn btn-danger btn-mini btn-file-action" type="button">删除</button>'
				+'</div>'
			+'</div>'
			+'<div class="div-file-size" id="">'+formatByte(((-1===fileList[i].size)?'/':fileList[i].size))+'</div>'
			+'<div class="div-file-time" id="">'+fileList[i].last_modified+'</div>'
		+'</li>';
	}		
	$('#ulFile').html(tempHtml);
	var folderlistCount = folderlist.length;
	if(1===folderlistCount){
		$('#aMyDiskFolderPath').attr('folderId',folderlist[0].folder_id);
		$('#liHiddenFolderPath').hide();
		$('#liCurrenFolderPath').hide();
		$('#liLastFolderPath').hide();
	}else if(2===folderlistCount){
		$('#liCurrenFolderPath').html(folderlist[0].folder_name).show();
		$('#aMyDiskFolderPath').attr('folderId',folderlist[1].folder_id);
		$('#liLastFolderPath').hide();
	}else if(2<folderlistCount){
		if(3<folderlistCount){
			$('#liHiddenFolderPath').show();
		}else{
			$('#liHiddenFolderPath').hide();
		}
		$('#liCurrenFolderPath').html(folderlist[0].folder_name).show();
		$('#aLastFolderPath').html(folderlist[1].folder_name).attr('folderId',folderlist[1].folder_id).parent().show();
		$('#aMyDiskFolderPath').attr('folderId',folderlist[folderlistCount-1].folder_id);
	}
	fileListDomEvent();
	$('#divFileCover').hide();
};

var fileListDomEvent = function(){
	$('#ulFile img').bind('error',function(){
		$(this).attr('src','./img/icon/icon-default.png');
	});
	
	$('#ulFile li').bind('mouseover',function(){
		$(this).children().next().next().children().next().show();
		_GLOBE_DATA('hoverFolderId',$(this).attr('folderId'));
		_GLOBE_DATA('hoverfileId',$(this).attr('fileId'));
	});
	
	$('#ulFile li').bind('mouseout',function(){
		$(this).children().next().next().children().next().hide();
	});
	
	$('#ulFile .span-file-name').bind('mouseover',function(){
		$(this).css('text-decoration','underline');
	});
	
	$('#ulFile .span-file-name').bind('mouseout',function(){
		$(this).css('text-decoration','none');
	});
	
	$('#ulFile .div-file-icon').bind('click',function(){
		openFolder();
	});
	
	$('#ulFile .span-file-name').bind('click',function(){
		openFolder();
	});
};

var openFolder = function(){
	var tempFolderId = _GLOBE_DATA('hoverFolderId');
	if('-1'!==tempFolderId){
		getFileList(tempFolderId);
	}
};

var traversal = function(obj,deep){
	for (var i in obj){
		if(obj.hasOwnProperty(i)){
			if(obj[i].length){
				var temp = deep+1;
				traversal(obj[i],temp);
			}else{
				_GLOBE_DATA('folderTreeTempHtml',_GLOBE_DATA('folderTreeTempHtml')
					+'<div class="div-folder-tree-name hidden">'
						+'<span class="folder-tree-unfold" style="margin-left:'+deep*20+'px;">'
						+'◥'
						+'</span>'
						+'<span class="span-folder-tree-name" folderId="'+obj[i].folder_id+'">'
							+'<img src="./img/icon/icon-folder.png" class="img-file-tree-icon"/>&nbsp;'
							+obj[i].folder_name
						+'&nbsp;</span>'
					+'</div>'
				+'<div class="file-tree-content">');
			}
		}
	}
	_GLOBE_DATA('folderTreeTempHtml',_GLOBE_DATA('folderTreeTempHtml')+'</div>');
	$('#folderTreeForCopyFile').html(_GLOBE_DATA('folderTreeTempHtml'));
};

var initTraversalEvent = function(){
	$($('.div-folder-tree-name')[0]).show().children().next().children().attr('src','./img/icon/boc_logo.png');
	$('#folderTreeForCopyFile .span-folder-tree-name').bind('click',function(){
		$('#folderTreeForCopyFile .span-folder-tree-name').css('background-color','transparent').css('color','rgb(51,51,51)');
		$(this).css('background-color','rgb(0, 136, 204)').css('color','white');
		_GLOBE_DATA('copyFileSelectedfolderId',$(this).attr('folderId'));
	});
	$('#folderTreeForCopyFile .folder-tree-unfold').bind('click',function(){
		if('◥'===$(this).html()){
			$(this).html('◢').parent().next().children().show();
		}else{
			$(this).html('◥').parent().next().children().hide();
		}
	});
};

var formatByte = function(size){
	if('number'!==(typeof size)){
		return size;
	}else if(1024>size){
		return size+' Byte';
	}else if(1048576>size){
		return ((size/1024).toFixed(2)+'').split('.00')[0]+' Mb';
	}else{
		return ((size/1024/1024).toFixed(2)+'').split('.00')[0]+' Gb';
	}
}

