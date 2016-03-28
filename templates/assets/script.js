$(function(){

    $('.nav-pills').sTabs({animate: true, startWith: 3});

    $('.panel-group .panel-heading').click(function(e){
        e.preventDefault();
        $(this).siblings('.panel-body').slideToggle(400);
    })

})
