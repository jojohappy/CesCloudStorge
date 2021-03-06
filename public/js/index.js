﻿
// 统一命名空间储存全局变量
var _GLOBE_DATA = (function() {
	var data = {
		hoverFolderId:'',
		folderTreeTempHtml:'',
		copyFileSelectedfolderId:'',
		hoverFileId:'',
		currentFolder:'',
		moveFileSelectedfolderId:'',
		batchFileIdList:'',
		batchFolderIdList:'',
		currentParentFolderId:'',
		bathcMoveFileSelectedfolderId:'',
		usedSpace:'',
		isTrash:'',
		trashId:'',
		isShare:'',
		createFolder:'',
		hasGroup:''
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
	if($(document.body)[0].clientWidth>900){
		$('#liTrash').css('left',($(document.body)[0].clientWidth/2-470)+460+'px');
	}
});		

var init = function(){
	
	$('#navbarUserName').html('admin');
	$('#ulJumbotronPath .hiddenLiPath').hide();
	usedSpaceChange();

	$('#loading').show();
	
	$.ajax({
		url:'http://172.17.10.61:8081/list/folders',
		data:{
			randomQuery: (new Date()).getTime()
		},
		success:function(data){
			var tempObj = data.folderlist;
			getFileList(data.folderlist[0].folder_id);
			
			traversal(tempObj,0);
			initTraversalEvent();
		},
		error:function(errorThrown){
		
		}
		
	});
	_GLOBE_DATA('createFolder',false);
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
	$('#sortFileSizeArrow').hide();
	$('#sortFileTimeArrow').hide();
};

var initDomEvent = function(){
	window.onbeforeunload = function() {
		return "此操作将会离开云存储，确定吗？"; // return 这句必不可少
	}
	$(document).bind('keydown', function (e) {
		var key = e.which;
		if (key == 13) {
			return false;
		}
	});
	
	$('#backBtn').click(function(){
		getFileList(_GLOBE_DATA('currentParentFolderId'));
	});
	
	$('#divFileTitle .title-file').bind('selectstart',function(){
		return false;
	});
	
	$('#divTitleFileName').bind('click',function(){
		$('#divFileTitle .sort-arrow-down').hide();
		$('#sortFileNameArrow').show().toggleClass('sort-arrow-up');
		getFileList(_GLOBE_DATA('currentFolder'),'file_name',$('#sortFileNameArrow').hasClass('sort-arrow-up')?'0':'1');
	});
	
	$('#divTitleFileSize').bind('click',function(){
		$('#divFileTitle .sort-arrow-down').hide();
		$('#sortFileSizeArrow').show().toggleClass('sort-arrow-up');
		getFileList(_GLOBE_DATA('currentFolder'),'file_size',$('#sortFileSizeArrow').hasClass('sort-arrow-up')?'0':'1');
	});
	
	$('#divTitleFileTime').bind('click',function(){
		$('#divFileTitle .sort-arrow-down').hide();
		$('#sortFileTimeArrow').show().toggleClass('sort-arrow-up');
		getFileList(_GLOBE_DATA('currentFolder'),'last_modified',$('#sortFileTimeArrow').hasClass('sort-arrow-up')?'0':'1');
	});
	
	$('#navbarUsedSpaceProgress').resize(function(){
		$('#navbarUsedSpaceText').html('已使用 '+_GLOBE_DATA('usedSpace')+' / 5 GB ('+(($('#navbarUsedSpaceProgress').width()/250)*100).toFixed(2)+'%)');
	});

	$('#navbarUserName').bind('mouseover',function(){

	});

	$('#divLogoutBtn').bind('mouseout',function(){
	
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
		$('#loading').show();
		if(''!==_GLOBE_DATA('copyFileSelectedfolderId')){
			$.ajax({
				url:'http://172.17.10.61:8081/file/copy',
				type:'POST',
				data:{
					file_id:_GLOBE_DATA('hoverFileId'),
					dest_folder_id:_GLOBE_DATA('copyFileSelectedfolderId'),
					randomQuery: (new Date()).getTime()
				},
				success:function(data){
					$('#copyFileCancle').trigger('click');
					if(0===data.result){
						successNotice('复制文件成功！');
						getFileList(_GLOBE_DATA('currentFolder'));
					}else{
						errorNotice('复制文件失败！');
					}
					usedSpaceChange();
					setTimeout("$('#loading').fadeOut();",300);
					_GLOBE_DATA('copyFileSelectedfolderId','');
				},
				error:function(errorThrown){
					$('#copyFileCancle').trigger('click');
					errorNotice('复制文件失败！');
				}
			});
		}else{
			alert('请选择目标文件夹！');
			setTimeout("$('#loading').fadeOut();",300);
		}
	});
	
	$('#batchCopyFileConfirm').bind('click',function(){
		$('#loading').show();
		if(''!==_GLOBE_DATA('copyFileSelectedfolderId')){
			$.ajax({
				url:'http://172.17.10.61:8081/file/copy',
				type:'POST',
				data:{
					file_id:_GLOBE_DATA('batchFileIdList'),
					dest_folder_id:_GLOBE_DATA('copyFileSelectedfolderId'),
					randomQuery: (new Date()).getTime()
				},
				success:function(data){
					$('#batchCopyFileCancle').trigger('click');
					if(0===data.result){
						successNotice('批量复制多个文件成功！');
						getFileList(_GLOBE_DATA('currentFolder'));
					}else{
						errorNotice('批量复制多个文件失败！');
					}
					usedSpaceChange();
					setTimeout("$('#loading').fadeOut();",300);
					_GLOBE_DATA('copyFileSelectedfolderId','');
				},
				error:function(errorThrown){
					$('#copyFileCancle').trigger('click');
					errorNotice('批量复制多个文件失败！');
				}
			});
		}else{
			alert('请选目标文件夹！');
		}
	});
	
	$('#moveConfirm').bind('click',function(){
		var tempFolderId = _GLOBE_DATA('hoverFolderId');
		var tempFileId = _GLOBE_DATA('hoverFileId');
		var tempType = '';
		if('-1'!==tempFolderId){
			tempType = 'folder';
		}
		if('-1'!==tempFileId){
			tempType = 'file';
		}
		$('#loading').show();
		if(''!==_GLOBE_DATA('moveFileSelectedfolderId')){
			$.ajax({
				url:'http://172.17.10.61:8081/'+tempType+'/move',
				type:'POST',
				data:{
					file_id:tempFileId,
					folder_id:tempFolderId,
					dest_folder_id:_GLOBE_DATA('moveFileSelectedfolderId'),
					randomQuery: (new Date()).getTime()
				},
				success:function(data){
					$('#moveCancle').trigger('click');
					if(0===data.result){
						successNotice('移动成功！');
						getFileList(_GLOBE_DATA('currentFolder'));
					}else{
						errorNotice('移动失败！');
					}
					setTimeout("$('#loading').fadeOut();",300);
					_GLOBE_DATA('moveFileSelectedfolderId','');
				},
				error:function(errorThrown){
					$('#moveCancle').trigger('click');
					errorNotice('移动失败！');
				}
			});
		}else{
			alert('请选择目标文件夹！');
			setTimeout("$('#loading').fadeOut();",300);
		}
	});
	
	$('#batchMoveConfirm').bind('click',function(){
		var tempFolderListId = _GLOBE_DATA('batchFolderIdList');
		var tempFileListId = _GLOBE_DATA('batchFileIdList');
		$('#loading').show();
		if(''!==_GLOBE_DATA('bathcMoveFileSelectedfolderId')){
			$.ajax({
				url:'http://172.17.10.61:8081/list/move',
				type:'POST',
				data:{
					folder_id:tempFolderListId,
					file_id:tempFileListId,
					dest_folder_id:_GLOBE_DATA('bathcMoveFileSelectedfolderId'),
					randomQuery: (new Date()).getTime()
				},
				success:function(data){
					$('#batchMoveCancle').trigger('click');
					if(_GLOBE_DATA('isTrash')){
						if(0===data.result){
							successNotice('批量还原多个文件/文件夹成功！');
							getFileList(_GLOBE_DATA('currentFolder'));
						}else{
							errorNotice('批量还原多个文件/文件夹失败！');
						}
					}else{
						if(0===data.result){
							successNotice('批量移动多个文件/文件夹成功！');
							getFileList(_GLOBE_DATA('currentFolder'));
						}else{
							errorNotice('批量移动多个文件/文件夹失败！');
						}
					}
					
					setTimeout("$('#loading').fadeOut();",300);
					_GLOBE_DATA('bathcMoveFileSelectedfolderId','');
				},
				error:function(errorThrown){
					$('#batchMoveCancle').trigger('click');
					if(_GLOBE_DATA('isTrash')){
						errorNotice('批量还原多个文件/文件夹失败！');
					}else{
						errorNotice('批量移动多个文件/文件夹失败！');
					}
				}
			});
		}else{
			alert('请选择目标文件夹！');
			setTimeout("$('#loading').fadeOut();",300);
		}
	});
	
	$('#batchDeleteConfirm').bind('click',function(){
	
		var tempFolderListId = _GLOBE_DATA('batchFolderIdList');
		var tempFileListId = _GLOBE_DATA('batchFileIdList');
		var isForever = _GLOBE_DATA('isTrash')?1:0;
		$('#loading').show();
		$.ajax({
			url:'http://172.17.10.61:8081/list/delete',
			type:'POST',
			data:{
				folder_id:tempFolderListId,
				file_id:tempFileListId,
				is_forever:isForever,
				randomQuery: (new Date()).getTime()
			},
			success:function(data){
				$('#batchDeleteCancle').trigger('click');
				if(0===data.result){
					successNotice('删除多个文件/文件夹成功！');
					getFileList(_GLOBE_DATA('currentFolder'));
				}else{
					errorNotice('删除多个文件/文件夹失败！');
				}
				usedSpaceChange();
				setTimeout("$('#loading').fadeOut();",300);
			},
			error:function(errorThrown){
				$('#batchDeleteCancle').trigger('click');
				errorNotice('删除多个文件/文件夹失败！');
			}
		});
	});
	
	$('#deleteConfirm').bind('click',function(){
	
		var tempFolderId = _GLOBE_DATA('hoverFolderId');
		var tempFileId = _GLOBE_DATA('hoverFileId');
		var isForever = _GLOBE_DATA('isTrash')?1:0;
		if('-1'!==tempFolderId){
			$('#loading').show();
			$.ajax({
				url:'http://172.17.10.61:8081/folder/delete',
				type:'POST',
				data:{
					folder_id:tempFolderId,
					is_forever:isForever,
					randomQuery: (new Date()).getTime()
				},
				success:function(data){
					$('#deleteCancle').trigger('click');
					if(0===data.result){
						successNotice('删除文件夹成功！');
						getFileList(_GLOBE_DATA('currentFolder'));
					}else{
						errorNotice('删除文件夹失败！');
					}
					usedSpaceChange();
					setTimeout("$('#loading').fadeOut();",300);
				},
				error:function(errorThrown){
					$('#deleteCancle').trigger('click');
					errorNotice('删除文件夹失败！');
				}
			});
		}
	
		if('-1'!==tempFileId){
			$('#loading').show();
			$.ajax({
				url:'http://172.17.10.61:8081/file/delete',
				type:'POST',
				data:{
					file_id:tempFileId,
					is_forever:isForever,
					randomQuery: (new Date()).getTime()
				},
				success:function(data){
					$('#deleteCancle').trigger('click');
					if(0===data.result){
						successNotice('删除文件成功！');
						getFileList(_GLOBE_DATA('currentFolder'));
					}else{
						errorNotice('删除文件失败！');
					}
					usedSpaceChange();
					setTimeout("$('#loading').fadeOut();",300);
				},
				error:function(errorThrown){
					$('#deleteCancle').trigger('click');
					errorNotice('删除文件失败！');
				}
			});
		}
		
	});
	
	$('#btnCreateFolder').bind('click',function(){
		if(!_GLOBE_DATA('createFolder')){
			_GLOBE_DATA('createFolder',true);
			$('#ulFile').prepend('<li id="liCreateFolder">'
				+'<div class="div-file-checkbox" id="">'
				+'</div>'
				+'<div class="div-file-icon" id="">'
				+'</div>'
				+'<div class="div-file-name-action" id="">'
					+'<input type="text" size="32"  maxlength="32" id="createFolderInput" class="create-folder-input" name="" />'
					+'<button id="createFolderConfirm" class="btn btn-info create-folder-confirm">确定</button>'
					+'<button id="createFolderCancle" class="btn create-folder-cancle">取消</button>'
				+'</div>'
				+'<div class="div-file-shared" id="">'
				+'</div>'
				+'<div class="div-file-size" id="">'
				+'</div>'
				+'<div class="div-file-time" id="">'
				+'</div>'
			+'</li>');
			initCreateFolderEvent();
		}
	});
	
	$('#batchDelete').bind('click',function(){
		var tempFileIdListCount = _GLOBE_DATA('batchFileIdList').split(',').length;
		var tempFolderIdListCount = _GLOBE_DATA('batchFolderIdList').split(',').length;
		if(4>tempFileIdListCount+tempFolderIdListCount){
			errorNotice('请选择至少两个文件/文件夹。');
			return false;
		}
	});
	
	$('#batchMove').bind('click',function(){
		getFileTree();
		$('#batchMoveH5').html('选择移动的位置,当前位置：'+$('#aMyDiskFolderPath').html()+(($('#liHiddenFolderPath').css('display')==='none')?'':$('#liHiddenFolderPath').html())+(($('#aLastFolderPath').html()==='')?'':'/')+$('#aLastFolderPath').html()+(($('#liCurrenFolderPath').css('display')==='none')?'':$('#liCurrenFolderPath').html()));
		var tempFileIdListCount = _GLOBE_DATA('batchFileIdList').split(',').length;
		var tempFolderIdListCount = _GLOBE_DATA('batchFolderIdList').split(',').length;
		if(4>tempFileIdListCount+tempFolderIdListCount){
			errorNotice('请选择至少两个文件/文件夹。');
			return false;
		}
	});
	
	$('#batchCopy').bind('click',function(){
		getFileTree();
		$('#copyH5').html('选择移动的位置,当前位置：'+$('#aMyDiskFolderPath').html()+(($('#liHiddenFolderPath').css('display')==='none')?'':$('#liHiddenFolderPath').html())+(($('#aLastFolderPath').html()==='')?'':'/')+$('#aLastFolderPath').html()+(($('#liCurrenFolderPath').css('display')==='none')?'':$('#liCurrenFolderPath').html()));
		$('#singleCopyBtn').hide();
		$('#batchCopyBtn').show();
		var tempFileIdListCount = _GLOBE_DATA('batchFileIdList').split(',').length;
		if(3>tempFileIdListCount){
			errorNotice('请选择至少两个文件，且不包含文件夹。');
			return false;
		}
	});
	
	$('#uploadBtn').bind('click',function(){
		if('Microsoft Internet Explorer'!==navigator.appName){
			if(!$('#attachment')[0].files[0]){
				alert('请选择要上传的文件！');
			}else{
				upload();
			}
		}else{
			if(document.getElementById('attachment').value){
				//console.log(document.getElementById('attachment').value);
				upload();
			}else{
				alert('请选择要上传的文件！');
			}
		}
	});
			
	$('#uploadSelectBtn').bind('click',function(){
		$('#attachment').trigger('click');
	});
	
	
	
	$('#toolbarUploadBtn').bind('click',function(){
		$('#selectFileInfo').html('');
		$('#divUpload input').remove();
		$('#divUpload').append(
			'<input type="file" id="attachment" name="attachment" style="float:left;" class=""/>'
		);
		if('Microsoft Internet Explorer'===navigator.appName){
			$('#uploadSelectBtn').hide();
			$('#selectFileInfo').hide();
		}else{
			$('#attachment').hide();
		}
		$('#attachment').bind('change',function(){
		
			if('Microsoft Internet Explorer'!==navigator.appName||' 10.0'==navigator.appVersion.split('MSIE')[1].split(';')[0]){
				if(100*1024*1024<this.files[0].size){
					alert('请勿上传大于100MB的文件！');
					$('#uploadCancle').trigger('click');
				}else{
					$('#selectFileInfo').html($(this).val().split('\\').pop());
				}
			}else{
				
			}
		});
		
	});
	
	$('#checkboxSelectAll').bind('change',function(){
		$('#ulFile .file-checkbox').trigger('click');
		if($(this)[0].checked){
			$('#ulFile .file-checkbox').attr('checked','checked');
		}else{
			$('#ulFile .file-checkbox').removeAttr('checked');
		}
	});
	
	$('#openShareFolder').bind('click',function(){
		getFileList(-20);
	});
};

var initCreateFolderEvent = function(){
	$('#createFolderInput').focus();

	$('#createFolderConfirm').bind('click',function(){
		_GLOBE_DATA('createFolder',false);
		$('#loading').show();
		$.ajax({
			url:'http://172.17.10.61:8081/folder/create',
			type:'POST',
			data:{
				parent_folder_id:_GLOBE_DATA('currentFolder'),
				new_folder_name:$('#createFolderInput').val(),
				randomQuery: (new Date()).getTime()
			},
			success:function(data){
				if(0===data.result){
					successNotice('创建文件夹成功！');
					getFileList(_GLOBE_DATA('currentFolder'));
				}else{
					errorNotice('创建文件夹失败！');
				}
				setTimeout("$('#loading').fadeOut();",300);
			},
			error:function(errorThrown){
				errorNotice('创建文件夹失败！');
			}
		});
	});
	
	$('#createFolderCancle').bind('click',function(){
		$('#liCreateFolder').remove();
		_GLOBE_DATA('createFolder',false);
	});
};

var initDomSize = function(){
	$('#ulFile').height($(document.body)[0].clientHeight-230);
	$('#loading').css('left',($(document.body)[0].clientWidth/2-55)+'px');
	$('#divNoticeInfo').css('left',($(document.body)[0].clientWidth/2-200)+'px');
	$('#folderTreeForCopyFile').css('padding-left',($('#folderTreeForCopyFile').width()/2-150)+'px');
	$('#folderTreeForMoveFile').css('padding-left',($('#folderTreeForMoveFile').width()/2-150)+'px');
};

var getFileList = function(folderId,sort,reverse){
	$('#checkboxSelectAll').removeAttr('checked');
	$('#liBatchMove').addClass('disabled','disabled');
	$('#liBatchDelete').addClass('disabled','disabled');
	$('#liBatchCopy').addClass('disabled','disabled');
	_GLOBE_DATA('batchFileIdList','');
	_GLOBE_DATA('batchFolderIdList','');
	if(!sort){
		$('#divFileTitle .sort-arrow-down').hide();
		$('#sortFileNameArrow').show().addClass('sort-arrow-up');
		sort='';
	}
	if(!reverse){
		reverse='';
	}
	$('#loading').show();
	_GLOBE_DATA('currentFolder',folderId);
	$.ajax({
		url:'http://172.17.10.61:8081/list/files',
		data:{
			folder_id:folderId,
			sort:sort,
			reverse:reverse,
			randomQuery: (new Date()).getTime()
		},
		success:function(data){
			_GLOBE_DATA('currentParentFolderId',data.parent_folder_id);
			if(-1===_GLOBE_DATA('currentParentFolderId')){
				_GLOBE_DATA('trashId',data.filelist[0].folder_id);
				_GLOBE_DATA('isTrash',false);
				_GLOBE_DATA('isShare',false);
				$('#batchMove').html('移动');
				$('#batchDelete').html('删除');
				$('#liBatchCopy').show();
				$('#liBatchMove').show();
				$('#liBatchDelete').show();
				$('#batchMoveLabel').html('移动');
				$('#batchMoveH5').html('选择移动的位置');
				$('#toolbarUploadBtn').removeAttr('disabled');
				$('#btnCreateFolder').removeAttr('disabled');
				$('#btnToolBarCover').hide();
			}else if(-10===_GLOBE_DATA('currentParentFolderId')){
				_GLOBE_DATA('isTrash',true);
				_GLOBE_DATA('currentParentFolderId','-1');
				$('#batchMove').html('还原');
				$('#batchDelete').html('永久删除');
				$('#liBatchCopy').hide();
				$('#liBatchMove').show();
				$('#liBatchDelete').show();
				$('#batchMoveLabel').html('还原');
				$('#batchMoveH5').html('选择还原的位置');
				$('#toolbarUploadBtn').attr('disabled','disabled');
				$('#btnCreateFolder').attr('disabled','disabled');
				$('#btnToolBarCover').show();
			}else if(-20===_GLOBE_DATA('currentParentFolderId')){
				_GLOBE_DATA('isShare',true);
				_GLOBE_DATA('isTrash',false);
				_GLOBE_DATA('currentParentFolderId','-1');
				$('#liBatchCopy').show();
				$('#liBatchMove').hide();
				$('#liBatchDelete').hide();
				$('#toolbarUploadBtn').attr('disabled','disabled');
				$('#btnCreateFolder').attr('disabled','disabled');
				$('#btnToolBarCover').show();
			}else{
				_GLOBE_DATA('isTrash',false);
				_GLOBE_DATA('isShare',false);
				$('#batchMove').html('移动');
				$('#batchDelete').html('删除');
				$('#liBatchCopy').show();
				$('#batchMoveLabel').html('移动');
				$('#batchMoveH5').html('选择移动的位置');
				$('#liBatchMove').show();
				$('#liBatchDelete').show();
				$('#toolbarUploadBtn').removeAttr('disabled');
				$('#btnCreateFolder').removeAttr('disabled');
				$('#btnToolBarCover').hide();
			}
			
			createFileListDom(data.filelist,data.folderlist);

			if(-1===_GLOBE_DATA('currentParentFolderId')){
				$('#backBtn').attr('disabled','disabled');
			}else{
				$('#backBtn').removeAttr('disabled');
			}
			setTimeout("$('#loading').fadeOut();",300);
		},
		error:function(errorThrown){
		
		}
	});
};

var downloadFile = function(fileId){
	window.open('http://172.17.10.61/file/download?file_id='+fileId+'&randomQuery='+(new Date()).getTime());
};

var createFileListDom = function(fileList,folderlist){
	var tempHtml= '<li class="li-trash" id="liTrash" folderId='+_GLOBE_DATA('trashId')+' fileId="-1">'
					+'<div class="div-file-icon" title="回收站">'
						+'<button class="btn img-file-icon trash-icon">回收站</button>'
					//	+'<img src="./img/icon/icon-trash.png" class="img-file-icon trash-icon"/>'
					+'</div>'
				+'</li>';
	if(_GLOBE_DATA('isTrash')){
		for(var i = 0; i<fileList.length;i++){
			tempHtml = tempHtml
			+'<li class="'+((0===i%2)?'li-background-blue':'')+'" folderId='+fileList[i].folder_id+' fileId='+fileList[i].file_id+'>'
				+'<div class="div-file-checkbox">'
					+'<input type="checkbox" class="file-checkbox"/>'
				+'</div>'
				+'<div class="div-file-icon">'
					+'<img src="./img/icon/icon-'+((''===fileList[i].mime_type)?'folder':fileList[i].mime_type)+'.png" class="img-file-icon"/>'
				+'</div>'
				+'<div class="div-file-name-action">'
					+'<div class="div-file-name"><span class="span-file-name">'+fileList[i].name+'</span></div>'
					+'<div class="div-file-action hidden">'
						+'<a href="#deleteModal" role="button" class="btn btn-mini btn-danger btn-file-action" type="button" data-toggle="modal">永久删除</a>'
						+'<a href="#moveModal" role="button" class="btn btn-mini btn-file-action btn-file-action-restore" type="button" data-toggle="modal">还原</a>'
					+'</div>'
				+'</div>'
				+'<div class="div-file-rename hidden">'
					+'<input type="text" class="create-folder-input rename-input" name="" />'
					+'<button class="btn btn-info create-folder-confirm rename-confirm">确定</button>'
					+'<button class="btn create-folder-cancle rename-cancle">取消</button>'
				+'</div>'
				+'<div class="div-file-shared"></div>'
				+'<div class="div-file-size">'+formatByte(((-1===fileList[i].size)?'/':fileList[i].size))+'</div>'
				+'<div class="div-file-time">'+fileList[i].last_modified+'</div>'
			+'</li>';
		}
	}else if(_GLOBE_DATA('isShare')){
		for(var i = 0; i<fileList.length;i++){
			tempHtml = tempHtml
				+'<li class="'+((tempNum===i%2)?'li-background-blue':'')+'" folderId='+fileList[i].folder_id+' fileId='+fileList[i].file_id+'>'
					+'<div class="div-file-checkbox">'
						+'<input type="checkbox" class="file-checkbox"/>'
					+'</div>'
					+'<div class="div-file-icon">'
						+'<img src="./img/icon/icon-'+((''===fileList[i].mime_type)?'folder':fileList[i].mime_type)+'.png" class="img-file-icon"/>'
					+'</div>'
					+'<div class="div-file-name-action">'
						+'<div class="div-file-name"><span class="span-file-name">'+fileList[i].name+'</span></div>'
						+'<div class="div-file-action hidden">'
							+((''===fileList[i].mime_type)?'':'<button class="btn btn-info btn-mini btn-file-action btn-file-download" type="button">下载</button>')
							+((''===fileList[i].mime_type)?'':'<a href="#copyModal" role="button" class="btn btn-mini btn-file-action btn-file-action-copy" type="button" data-toggle="modal">复制</a>')
						+'</div>'
					+'</div>'
					+'<div class="div-file-rename hidden">'
						+'<input type="text" class="create-folder-input rename-input" name="" />'
						+'<button class="btn btn-info create-folder-confirm rename-confirm">确定</button>'
						+'<button class="btn create-folder-cancle rename-cancle">取消</button>'
					+'</div>'
					+'<div class="div-file-shared"></div>'
					+'<div class="div-file-size">'+formatByte(((-1===fileList[i].size)?'/':fileList[i].size))+'</div>'
					+'<div class="div-file-time">'+fileList[i].last_modified+'</div>'
				+'</li>';
		}
	}else{
		var tempNum = 0;
		for(var i = 0; i<fileList.length;i++){
			if(-10===fileList[i].parent_folder_id){
				tempNum = 1;
			}else{
				tempHtml = tempHtml
				+'<li class="'+((tempNum===i%2)?'li-background-blue':'')+'" folderId='+fileList[i].folder_id+' fileId='+fileList[i].file_id+'>'
					+'<div class="div-file-checkbox">'
						+'<input type="checkbox" class="file-checkbox"/>'
					+'</div>'
					+'<div class="div-file-icon">'
						+'<img src="./img/icon/icon-'+((''===fileList[i].mime_type)?'folder':fileList[i].mime_type)+'.png" class="img-file-icon"/>'
					+'</div>'
					+'<div class="div-file-name-action">'
						+'<div class="div-file-name"><span class="span-file-name">'+fileList[i].name+((0===fileList[i].share.length)?'':'')+'</span></div>'
						+'<div class="div-file-action hidden">'
							+((''===fileList[i].mime_type)?'':'<button class="btn btn-info btn-mini btn-file-action btn-file-download" type="button">下载</button>')
							+'<a href="#moveModal" role="button" class="btn btn-mini btn-file-action btn-file-action-move" type="button" data-toggle="modal">移动</a>'
							+((''===fileList[i].mime_type)?'':'<a href="#copyModal" role="button" class="btn btn-mini btn-file-action btn-file-action-copy" type="button" data-toggle="modal">复制</a>')
							+'<button class="btn btn-mini btn-file-action btn-rename" type="button">重命名</button>'
							+'<a href="#deleteModal" role="button" class="btn btn-mini btn-danger btn-file-action" type="button" data-toggle="modal">删除</a>'
							+((''===fileList[i].mime_type)?'':'<a role="button" class="btn btn-mini btn-file-action btn-file-action-share" type="button">分享</a>')
							+((0===fileList[i].share.length)?'':'<a role="button" class="btn btn-mini btn-file-action btn-file-action-unshare" type="button">取消分享</a>')
						+'</div>'
					+'</div>'
					+'<div class="div-file-rename hidden">'
						+'<input type="text" class="create-folder-input rename-input" name="" />'
						+'<button class="btn btn-info create-folder-confirm rename-confirm">确定</button>'
						+'<button class="btn create-folder-cancle rename-cancle">取消</button>'
					+'</div>'
					+'<div class="div-file-shared">'+((0===fileList[i].share.length)?'':'✔')+'</div>'
					+'<div class="div-file-size">'+formatByte(((-1===fileList[i].size)?'/':fileList[i].size))+'</div>'
					+'<div class="div-file-time">'+fileList[i].last_modified+'</div>'
				+'</li>';
			}
		}
	}
	$('#ulFile').html(tempHtml);

	var folderlistCount = folderlist.length;
	if(1===folderlistCount){
		$('#aMyDiskFolderPath').attr('folderId',folderlist[0].folder_id);
		$('#liHiddenFolderPath').hide();
		$('#liCurrenFolderPath').hide();
		$('#liLastFolderPath').hide();
	}else if(2===folderlistCount){
		$('#liCurrenFolderPath').html('<span class="divider">/</span>'+folderlist[0].folder_name).show();
		$('#aMyDiskFolderPath').attr('folderId',folderlist[1].folder_id);
		$('#liLastFolderPath').hide();
	}else if(2<folderlistCount){
		if(3<folderlistCount){
			$('#liHiddenFolderPath').show();
		}else{
			$('#liHiddenFolderPath').hide();
		}
		$('#liCurrenFolderPath').html('<span class="divider">/</span>'+folderlist[0].folder_name).show();
		$('#aLastFolderPath').html(folderlist[1].folder_name).attr('folderId',folderlist[1].folder_id).parent().show();
		$('#aMyDiskFolderPath').attr('folderId',folderlist[folderlistCount-1].folder_id);
	}
	fileListDomEvent();

};

var fileListDomEvent = function(){
	$('#liTrash').css('left',($(document.body)[0].clientWidth/2-470)+460+'px');
	$('#loading').show();
	$.ajax({
		url:'http://172.17.10.61:8081/tenants',
		type:'GET',
		data:{
			randomQuery: (new Date()).getTime()
		},
		success:function(data){
			var tmpHtml = '<ul id="ulTenants">';
			var tempObj = data.tenants;
			if(tempObj){
				_GLOBE_DATA('hasGroup',true);
				for(var i = 0;i<tempObj.length;i++){
					tmpHtml = tmpHtml + '<li class="li-tenants" tenantsId="'+tempObj[i].id+'" onclick="liTenantsClick(event)">'+tempObj[i].name+'</li>'
				}
				tmpHtml = tmpHtml+'</ul>';
				$('#ulFile .btn-file-action-share').popover({
					placement:'right',
					title:'选择分享工作区',
					content:tmpHtml,
					html:'true'
				});
			}else{
				_GLOBE_DATA('hasGroup',false);
			}
			setTimeout("$('#loading').fadeOut();",300);
		},
		error:function(errorThrown){
		}
	});
	$('#ulFile .btn-file-action-share').bind('click',function(){
		if(!_GLOBE_DATA('hasGroup')){
			errorNotice('您尚未加入任何小组，无法分享文件！');
		}
	});
	
	$('#ulFile .btn-file-action-unshare').bind('click',function(){
		getFileTree();
		$.ajax({
			url:'http://172.17.10.61:8081/share',
			data:{
				entity:'private',
				file_id:_GLOBE_DATA('hoverFileId'),
				randomQuery: (new Date()).getTime()
			},
			success:function(data){
				if(0===data.result){
					successNotice('取消文件共享成功！');
					//getFileList(_GLOBE_DATA('currentFolder'));
				}else{
					errorNotice('取消文件共享失败！');
				}
				getFileList(_GLOBE_DATA('currentFolder'));
			},
			error:function(errorThrown){
				errorNotice('取消文件共享失败！');
			}
		});
	});
	
	$('#ulFile .file-checkbox').bind('change',function(){
		$('#liBatchMove').addClass('disabled');
		$('#liBatchCopy').addClass('disabled');
		$('#liBatchDelete').addClass('disabled');
		var tempCheckedFileIdList = '';
		var tempCheckedFolderIdList = '';
		var tempCheckedList = $('.file-checkbox:checked');
		for(var i = 0; i<tempCheckedList.length;i++){
			var tempFileId = $(tempCheckedList[i]).parent().parent().attr('fileId');
			var tempFolderId = $(tempCheckedList[i]).parent().parent().attr('folderId');
			if('-1'!==tempFileId){
				tempCheckedFileIdList = tempFileId+','+tempCheckedFileIdList;
			}
			if('-1'!==tempFolderId){
				tempCheckedFolderIdList = tempFolderId+','+tempCheckedFolderIdList;
			}
		}
		_GLOBE_DATA('batchFileIdList',tempCheckedFileIdList);
		_GLOBE_DATA('batchFolderIdList',tempCheckedFolderIdList);
		var tempFileIdListCount = _GLOBE_DATA('batchFileIdList').split(',').length;
		var tempFolderIdListCount = _GLOBE_DATA('batchFolderIdList').split(',').length;
		if(3<tempFileIdListCount+tempFolderIdListCount){
			$('#liBatchMove').removeClass('disabled');
			$('#liBatchDelete').removeClass('disabled');
		}
		if(1===tempFolderIdListCount&&2<tempFileIdListCount){
			$('#liBatchCopy').removeClass('disabled');
			$('#btnBatchDropdown').dropdown();
		}
	});
	
	$('#ulFile img').bind('error',function(){
		$(this).attr('src','./img/icon/icon-default.png');
	});
	
	$('#ulFile li').bind('mouseover',function(){
		$(this).children(':first').next().next().children(':first').next().show();
		_GLOBE_DATA('hoverFolderId',$(this).attr('folderId'));
		_GLOBE_DATA('hoverFileId',$(this).attr('fileId'));
	});
	
	$('#ulFile li').bind('mouseout',function(){
		$(this).children(':first').next().next().children(':first').next().hide();
	});
	
	$('#ulFile .span-file-name').bind('mouseover',function(){
		$(this).css('text-decoration','underline');
	});
	
	$('#ulFile .span-file-name').bind('mouseout',function(){
		$(this).css('text-decoration','none');
	});
	
	$('#ulFile .div-file-icon').bind('click',function(){
		openFileOrFolder();
	});
	
	$('#ulFile .span-file-name').bind('click',function(){
		openFileOrFolder();
	});
	
	$('#ulFile .btn-file-download').bind('click',function(){
		openFileOrFolder();
	});
	
	$('#ulFile .btn-file-action-move').bind('click',function(){
		getFileTree();
		$('#moveLabel').html('移动');

		$('#moveH5').html('选择移动的位置,当前位置：'+$('#aMyDiskFolderPath').html()+(($('#liHiddenFolderPath').css('display')==='none')?'':$('#liHiddenFolderPath').html())+(($('#aLastFolderPath').html()==='')?'':'/')+$('#aLastFolderPath').html()+(($('#liCurrenFolderPath').css('display')==='none')?'':$('#liCurrenFolderPath').html()));
	});
	
	$('#ulFile .btn-file-action-restore').bind('click',function(){
		getFileTree();
		$('#moveLabel').html('还原');
		$('#moveH5').html('选择还原的位置');
	});
	
	$('#ulFile .btn-file-action-copy').bind('click',function(){
		$('#singleCopyBtn').show();
		$('#batchCopyBtn').hide();
		
		$('#copyH5').html('选择移动的位置,当前位置：'+$('#aMyDiskFolderPath').html()+(($('#liHiddenFolderPath').css('display')==='none')?'':$('#liHiddenFolderPath').html())+(($('#aLastFolderPath').html()==='')?'':'/')+$('#aLastFolderPath').html()+(($('#liCurrenFolderPath').css('display')==='none')?'':$('#liCurrenFolderPath').html()));
		getFileTree();
	});
	
	$('#ulFile .btn-rename').bind('click',function(){
		$(this).parent().parent().hide().next().show().children(':first').val($($(this).parent().prev().children()[0]).html());
	});
	
	$('#ulFile .rename-confirm').bind('click',function(){
		var tempFolderId = _GLOBE_DATA('hoverFolderId');
		var tempFileId = _GLOBE_DATA('hoverFileId');
		var tempType = '';
		if('-1'!==tempFolderId){
			tempType = 'folder';
		}
		if('-1'!==tempFileId){
			tempType = 'file';
		}
		$('#loading').show();
		$.ajax({
			url:'http://172.17.10.61:8081/'+tempType+'/rename',
			type:'POST',
			data:{
				folder_id:tempFolderId,
				file_id:tempFileId,
				new_folder_name:$(this).prev().val(),
				new_file_name:$(this).prev().val(),
				randomQuery: (new Date()).getTime()
			},
			success:function(data){
				if(0===data.result){
					successNotice('重命名成功！');
					getFileList(_GLOBE_DATA('currentFolder'));
				}else{
					errorNotice('重命名失败！');
				}
				setTimeout("$('#loading').fadeOut();",300);
			},
			error:function(errorThrown){
				errorNotice('重命名失败！');
			}
		});
	});
	
	$('#ulFile .rename-cancle').bind('click',function(){
		$(this).parent().hide().prev().show();
	});
};

var liTenantsClick = function(e){
	$('#loading').show();
	$.ajax({
		url:'http://172.17.10.61:8081/share',
		data:{
			share_tenants:e.target?($(e.target).attr('tenantsId')):($(e.srcElement).attr('tenantsId')),
			entity:'share',
			file_id:e.target?($(e.target).parent().parent().parent().parent().parent().parent().attr('fileId')):($(e.srcElement).parent().parent().parent().parent().parent().parent().attr('fileId')),
			randomQuery: (new Date()).getTime()
		},
		success:function(data){
			e.target?($(e.target).parent().parent().parent().prev().popover('hide')):($(e.srcElement).parent().parent().parent().prev().popover('hide'));
			if(0===data.result){
				successNotice('文件共享成功！');
				//getFileList(_GLOBE_DATA('currentFolder'));
			}else{
				errorNotice('文件共享失败！');
			}
			getFileList(_GLOBE_DATA('currentFolder'));
		},
		error:function(jqXHR,textStatus,errorThrown){
			errorNotice('文件共享失败！');
		}
	});
	
};

var openFileOrFolder = function(){

	if(_GLOBE_DATA('isTrash')){

	}else{
		var tempFolderId = _GLOBE_DATA('hoverFolderId');
		var tempFileId = _GLOBE_DATA('hoverFileId');
		if('-1'!==tempFolderId){
			getFileList(tempFolderId);
		}
		
		if('-1'!==tempFileId){
			downloadFile(tempFileId);
		}
	}
};

var getFileTree = function(){
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
							+obj[i].folder_name+(('Microsoft Internet Explorer'===navigator.appName&&4===parseFloat(navigator.appVersion))?'　':'')
						+'&nbsp;</span>'
					+'</div>'
				+'<div class="file-tree-content">');
			}
		}
	}
	_GLOBE_DATA('folderTreeTempHtml',_GLOBE_DATA('folderTreeTempHtml')+'</div>');
	$('#folderTreeForCopyFile').html(_GLOBE_DATA('folderTreeTempHtml'));
	$('#folderTreeForMoveFile').html(_GLOBE_DATA('folderTreeTempHtml'));
	$('#folderTreeForBatchMoveFile').html(_GLOBE_DATA('folderTreeTempHtml'));
};

var initTraversalEvent = function(){
	_GLOBE_DATA('folderTreeTempHtml','');
	$($('#folderTreeForCopyFile .div-folder-tree-name')[0]).show().children().next().children().attr('src','./img/icon/boc_logo.png');
	$($('#folderTreeForMoveFile .div-folder-tree-name')[0]).show().children().next().children().attr('src','./img/icon/boc_logo.png');
	$($('#folderTreeForBatchMoveFile .div-folder-tree-name')[0]).show().children().next().children().attr('src','./img/icon/boc_logo.png');
	
	$('#folderTreeForCopyFile .span-folder-tree-name').bind('click',function(){
		$('#folderTreeForCopyFile .span-folder-tree-name').css('background-color','transparent').css('color','rgb(51,51,51)');
		$(this).css('background-color','rgb(0, 136, 204)').css('color','white');
		_GLOBE_DATA('copyFileSelectedfolderId',$(this).attr('folderId'));
	});
	$('#folderTreeForMoveFile .span-folder-tree-name').bind('click',function(){
		$('#folderTreeForMoveFile .span-folder-tree-name').css('background-color','transparent').css('color','rgb(51,51,51)');
		$(this).css('background-color','rgb(0, 136, 204)').css('color','white');
		_GLOBE_DATA('moveFileSelectedfolderId',$(this).attr('folderId'));
	});
	$('#folderTreeForBatchMoveFile .span-folder-tree-name').bind('click',function(){
		$('#folderTreeForBatchMoveFile .span-folder-tree-name').css('background-color','transparent').css('color','rgb(51,51,51)');
		$(this).css('background-color','rgb(0, 136, 204)').css('color','white');
		_GLOBE_DATA('bathcMoveFileSelectedfolderId',$(this).attr('folderId'));
	});
	
	$('#folderTreeForCopyFile .folder-tree-unfold').bind('click',function(){
		if('◥'===$(this).html()){
			$(this).html('◢').parent().next().children().show();
		}else{
			$(this).html('◥').parent().next().children().hide();
		}
	});
	$('#folderTreeForMoveFile .folder-tree-unfold').bind('click',function(){
		if('◥'===$(this).html()){
			$(this).html('◢').parent().next().children().show();
		}else{
			$(this).html('◥').parent().next().children().hide();
		}
	});
	$('#folderTreeForBatchMoveFile .folder-tree-unfold').bind('click',function(){
		if('◥'===$(this).html()){
			$(this).html('◢').parent().next().children().show();
		}else{
			$(this).html('◥').parent().next().children().hide();
		}
	});
	$($($('#folderTreeForCopyFile .div-folder-tree-name')[0]).children()[0]).click();
	$($($('#folderTreeForMoveFile .div-folder-tree-name')[0]).children()[0]).click();
	$($($('#folderTreeForBatchMoveFile .div-folder-tree-name')[0]).children()[0]).click();
	
};

var usedSpaceChange = function(){
	$.ajax({
		url:'http://172.17.10.61:8081/user/used_space',
		data:{
			randomQuery: (new Date()).getTime()
		},
		success:function(data){
			_GLOBE_DATA('usedSpace',formatByte(parseInt(data.used_space)));
			$('#navbarUsedSpaceProgress').animate({
				width:((parseInt(data.used_space)/1024/1024/1024)*100)/5+'%'
			},{
				duration:500,
				easing:'linear'
			});
			$('#navbarUsedSpaceText').html('已使用 '+_GLOBE_DATA('usedSpace')+' / 5 GB ('+(($('#navbarUsedSpaceProgress').width()/250)*100).toFixed(2)+'%)');
		},
		error:function(errorThrown){
		
		}
	});
};

var successNotice = function(text){
	//$('#noticeText').html(text);
	//$('#noticeButton').addClass('btn-success').removeClass('btn-danger');
	//$('#noticeLargeError').hide();
	//$('#noticeLargeSuccess').show();
	//$('#notice').modal('show');
	$('#divNoticeInfo').stop();
	$('#divNoticeInfo').html(text).removeClass('bg-red').animate({height:'30px'},{queue:false}).delay(5000).animate({height:'0px'},{queue:true});
	//setTimeout("$('#divNoticeInfo').animate({height:'0px'},{queue:false});",5000);
};

var errorNotice = function(text){
	//$('#noticeText').html(text);
	//$('#noticeButton').addClass('btn-danger').removeClass('btn-success');
	//$('#noticeLargeError').show();
	//$('#noticeLargeSuccess').hide();
	//$('#notice').modal('show');
	$('#divNoticeInfo').stop();
	$('#divNoticeInfo').html(text).addClass('bg-red').animate({height:'30px'},{queue:false}).delay(5000).animate({height:'0px'},{queue:true});
	//setTimeout("$('#divNoticeInfo').animate({height:'0px'},{queue:false});",5000);
	setTimeout("$('#loading').fadeOut();",300);
};

var formatByte = function(size){
	if('number'!==(typeof size)){
		return size;
	}else if(1024>size){
		return size+' Byte';
	}else if(1048576>size){
		return ((size/1024).toFixed(2)+'').split('.00')[0]+' KB';
	}else if(1073741824>size){
		return ((size/1024/1024).toFixed(2)+'').split('.00')[0]+' MB';
	}else{
		return ((size/1024/1024/1024).toFixed(2)+'').split('.00')[0]+' GB';
	}
}

var upload = function(){
	$("#uploadLoading").show();
	//console.log($('#attachment').val());
	$.ajaxFileUpload({
		url:'http://172.17.10.61:8081/file/upload',//用于文件上传的服务器端请求地址
		secureuri:false,//一般设置为false
		fileElementId:'attachment',//文件上传空间的id属性  <input type="file" id="file" name="file" />
		dataType: 'text/html',//返回值类型 一般设置为json
		data:{
			current_folder_id:_GLOBE_DATA('currentFolder'),
			randomQuery:(new Date()).getTime()
		},
		complete:function(xmlhttp,textStatus ){
			$('#attachment').remove();
			$("#uploadLoading").hide();
			$('#uploadCancle').trigger('click');
			getFileList(_GLOBE_DATA('currentFolder'));
			if('success'==xmlhttp.responseText){
				usedSpaceChange();
				successNotice('上传成功!');
			}else{
				errorNotice('上传失败!请确定没有重复文件且小于100M');
			}
		},
		success:function(data,textStatus,jqXHR){

		},
		error:function( jqXHR, textStatus, errorThrown){

		}
	});
}
