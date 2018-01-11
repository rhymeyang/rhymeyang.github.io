---
layout: null
---

/*Include Data Base*/
{% include dbase/dbase %}

jQuery(document).ready(function($) {
    if ($('#curpage').length >0){

        const page_count = parseInt($('#curpage').attr('pagemax'));
    
        if (isNaN(page_count)| page_count<=0){return;}

        let page_array = new Array();
        for(let index =1; index<=page_count; index++){
            page_array.push(`page${index}`);
        }

        function set_page(page_num){
            if(page_num<1 | page_num > page_array.length){return;}
            $(`.page${page_num}`).removeClass('hide');
            $('#curpage').text(page_num);
            for (let page_index of page_array){
                if (page_index === `page${page_num}`){continue;}
                $(`.${page_index}`).addClass('hide');
            }
        }
        $('#firstpage').on('click', function(){set_page(1);});
        $('#lastpage').on('click', function(){set_page(page_count);});
        $('#pagepre').on('click', function(){set_page(parseInt($('#curpage').text()) -1);});
        $('#pageafter').on('click', function(){set_page(parseInt($('#curpage').text()) +1);});
     }
});
