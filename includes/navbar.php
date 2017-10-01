
 <a href="#event-categ-panel" class="ui-btn-left "   data-iconpos="notext" data-display="reveal" data-icon="gear" > Browse Categories </a>  
              <h1>  Egate  </h1>   
              <a href="#admin-option-panel" class="ui-btn-right" data-iconpos="notext" data-display="push" data-icon="edit"> Options </a>          
              <nav data-role="navbar" >             
                  <ul>                
                      <li>
                          <a class="ui-active ui-persiste" href="#eventsList" data-icon="grid"> Browse Event </a>
                      </li>                  
                      <li>
                          <a href="processor.php?logout=true" id="log-off-btn"  data-icon="info" data-ajax="false"> Learn More </a>
                      </li>
            <?php if(!$session->is_loged_in()){ ?>                
                      <li>
                          <a href="sign_up_page.php" data-icon="user" id="#my-ext" data-ajax="false" > Sign Up </a>
                      </li>            
                      <li>
                          <a href="#log-in-dialog" data-icon="arrow-r"> Log in </a>
                      </li>          
                 <?php } else { ?>
                        <li>
                          <a href="#admin-option-panel" data-icon="user"> Account </a>
                      </li>       
                    <?php } ?> 
                      <li>
                          <a href="new_event_form.php"  id="create-event-page-btn" data-icon="edit"> Create Event </a>
                      </li>       
                  </ul>          
              </nav>         
              <form class="ui-filterable">     
                    <input id="filter-input" data-type="search">     
              </form>

              <script type="text/javascript">
         
      $('#create-event-page-btn').click(function(){
            $.post("../processor.php",  {create: '2'},
                        function(data){
                        
                         
                        alert(data);
                        }  );
          });
           

              </script>
       