class HomeController < ApplicationController
   #dropbox constants  
  APP_KEY = 'frm9p5h8990e888'
  APP_SECRET = '5lnge08bkoauzhi'
  DROPREDIRECT_URI = 'https://safeclod.herokuapp.com/home/dropauth'
  require 'dropbox_sdk'


  def index
  	@dat=Detail.all
  	puts @dat
  	 if !Dir.exists?(Rails.root.join('filespace')) then
        Dir.mkdir(Rails.root.join('filespace'))
      #To store the uploaded files b4 RAIDing
      end
  end

  def upload
  	puts "************Inside controller: Home & action: Upload****************"
 	uploaded_io = params[:file]
  	File.open(Rails.root.join('filespace', uploaded_io.original_filename), 'wb') do |file|
    	file.write(uploaded_io.read)
	end

	det= Detail.new
    det.filename=uploaded_io.original_filename
    det.status="READY"
    det.save
   # save split file names to db

    # get ranmdom names for split filespace
    letter = [('a'..'z'),('A'..'Z')].map { |i| i.to_a  }.flatten
    split1 = (0..8).map{ letter[rand(letter.length)]}.join
    det.s1=split1+".scs"
    letter = [('a'..'z'),('A'..'Z')].map { |i| i.to_a  }.flatten
    split2 = (0..8).map{ letter[rand(letter.length)]}.join
    det.s2=split2+".scs"
    det.save

    # get ranmdom names for split filespace close
   # rec.status=true
    
    image_a = File.open(Rails.root.join('filespace', det.filename), 'r')
    image_b = File.open(Rails.root.join('filespace', det.s1), 'w+')
    image_c = File.open(Rails.root.join('filespace', det.s2), 'w+')

      n=2
      image_a.each_line do |l|
          if n%2==0
            image_b.write(l)    
          else
             image_c.write(l)
          end
        n=n+1
      end
  image_a.close
  image_b.close
  image_c.close
	File.delete(Rails.root.join('filespace', det.filename))
      redirect_to :controller => "home", :action => 'index'
  end


def dropauth

    puts "********************Inside  dropauth"
    if params[:code]==nil
          session[:user]="jagan26@gmail.com"
          csrf_token_session_key = :dropbox_auth_csrf_token
          @@flow = DropboxOAuth2Flow.new(APP_KEY, APP_SECRET, DROPREDIRECT_URI, session, csrf_token_session_key)
          authorize_url = @@flow.start()
          redirect_to authorize_url
        else
          access_token, user_id= @@flow.finish(params)
          cld=Detail.last
          cld.drop=access_token
          cld.save
          redirect_to :controller => "home", :action => 'boxauth'
          end
  end

  def boxauth

    puts "********************Inside  boxauth"
      if params[:code]==nil
          
            require 'ruby-box'
          session = RubyBox::Session.new({
            client_id: 'skamrg791rspftegmigusyevx2pup49y',
            client_secret: '6sj2CBbfGU0eFdfJojTxJOu36DtVyKG6'
          })
          authorize_url = session.authorize_url('https://safeclod.herokuapp.com/home/boxauth')
          redirect_to authorize_url
      else
        
          session = RubyBox::Session.new({
            client_id: 'skamrg791rspftegmigusyevx2pup49y',
            client_secret: '6sj2CBbfGU0eFdfJojTxJOu36DtVyKG6'
          })
           code=params[:code]
          @token = session.get_access_token(code)
          tok= @token.token # the access token.
           cld=Detail.last
          cld.box=tok
          cld.save
           # redirect_to :controller => "cloud", :action => 'googoauth'
          dropup
      end
  end

  def dropup
  	puts "********************Inside controller: Cloud & action: dropup"
    # @file = params[:pa]
      cld=Detail.find_by(status: 'READY')
                # Upload file code here
            access_token=cld.drop
            client = DropboxClient.new(access_token)
            puts "linked account:", client.account_info().inspect
            file = File.open(Rails.root.join('filespace', cld.s1), 'r')#open('working-draft.txt')
            @t1= Time.now.strftime("%Y-%m-%d %H:%M:%S.%L");
            puts @t1
            puts "***********************Dropbox upload*****************************************************************"
            response = client.put_file(cld.s1, file)
            @t2= Time.now.strftime("%Y-%m-%d %H:%M:%S.%L");
            file.close
            puts @t2
           puts "uploaded:", response.inspect
           File.delete(Rails.root.join('filespace', cld.s1))
           boxup
    
  end

  def boxup
  	puts "********************Inside controller: Cloud & action: boxup"
           cld=Detail.find_by(status: 'READY')
        tok=cld.box
            session = RubyBox::Session.new({
              client_id: 'skamrg791rspftegmigusyevx2pup49y',
              client_secret: '6sj2CBbfGU0eFdfJojTxJOu36DtVyKG6',
              access_token: tok
            })
            client = RubyBox::Client.new(session)
        pathh= (Rails.root.join('filespace', cld.s2)).to_s
            @t1= Time.now.strftime("%Y-%m-%d %H:%M:%S.%L");
            puts @t1
            puts "***********************box upload*****************************************************************"
          
          file = client.upload_file(pathh, '/csc/', overwrite=true) # lookups by id are more efficient
          @t2= Time.now.strftime("%Y-%m-%d %H:%M:%S.%L");
            puts @t2
            cld.status="CLOUD"
            cld.save
            File.delete(Rails.root.join('filespace', cld.s2))
    redirect_to :controller => "home", :action => 'index'
  end

def clddownload
    puts "********************Inside controller: Cloud & action: download"
    # S1,S2 from drop and s3 form Box
    @file=params[:pa]
    det =Detail.find_by(filename: params[:pa])
    det.status="DOWNLOADING"
    det.save
    
    
      # Download S1
      dropdown(det.s1)
      puts "Drop S1 download success"
	  # Download S2
      boxdown(det.s2)
      puts "Box S2 download success"
       image_a = File.open(Rails.root.join('filespace', det.filename), 'w+')
    image_b = File.open(Rails.root.join('filespace', det.s1), 'r')
    image_c = File.open(Rails.root.join('filespace', det.s2), 'r')

      
    image_b.each_line do |l|
    m=image_c.gets
    image_a.write(l)        
    image_a.write(m)
  end
      image_a.close
  image_b.close
  image_c.close
	File.delete(Rails.root.join('filespace', det.s1))
	File.delete(Rails.root.join('filespace', det.s2))
      


     det.status="LOCAL"
    det.save
    redirect_to home_index_path

  end

  def dropdown(dfile)
    puts "********************Inside controller: Cloud & action: dropdown"
    # # Download from dropbox
    
     access_token=Detail.last.drop
     client = DropboxClient.new(access_token)
     @t1= Time.now.strftime("%Y-%m-%d %H:%M:%S.%L");
    puts @t1
    puts "***********************Dropbox Download*****************************************************************"          
    contents, metadata = client.get_file_and_metadata(dfile)        
    File.open(Rails.root.join('filespace', dfile), 'wb') {|f| f.puts contents }
    @t2= Time.now.strftime("%Y-%m-%d %H:%M:%S.%L");
    puts @t2
    
    return
  end  

  def boxdown(dfile)
    puts "********************Inside controller: Cloud & action: boxdown"
    # Download from box
    # S2=params[:pa]
     tok=Detail.last.box
            session = RubyBox::Session.new({
              client_id: 'skamrg791rspftegmigusyevx2pup49y',
              client_secret: '6sj2CBbfGU0eFdfJojTxJOu36DtVyKG6',
              access_token: tok
            })
            client = RubyBox::Client.new(session)
      cfile='/csc/'+ dfile
      puts cfile
      @t1= Time.now.strftime("%Y-%m-%d %H:%M:%S.%L");
            puts @t1
            puts "***********************box Download*****************************************************************"
          
#           f = File.open(Rails.root.join('filespace', @file), 'wb')#open('./LOCAL.txt', 'w+')
# f.write( client.file('cfile').download )
# f.close()
      content = client.file(cfile).download 
      File.open(Rails.root.join('filespace', dfile), 'wb') {|f| f.puts content }
      @t2= Time.now.strftime("%Y-%m-%d %H:%M:%S.%L");
            puts @t2
     
     return
       end



  def download
  	puts "************Inside controller: Home & action: Download****************"
    @file = params[:pa]
    send_file Rails.root.join('filespace',  @file),  :x_sendfile=>true
  end

  def delete
     file = params[:pa]
      det =Detail.find_by(filename: file)
      File.delete(Rails.root.join('filespace', det.filename))
      det.destroy 
      redirect_to :controller => "home",:action => 'index'
  end
end
