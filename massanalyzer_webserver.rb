require 'rubygems'
require 'sinatra'

set :port, 3000

#generate a random string to save the inputted mzxml file
def String.random_alphanumeric(size=16)
  s = ""
  size.times { s << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
  s
end

def generate_file_path(params)
  fasta_file_path = File.join("public", params[:filename] + ".out")
  fasta_file_path
end

def generate_specplot_images(peptide, mgf_location, outname)
  image_location = mgf_location+".png"
  
  specplot_exe = "./specplot_uncapped_cys "
  specplot_exe += " --mgf " + mgf_location
  specplot_exe += " --spectrum 1 "
  specplot_exe += " --peptide " + peptide
  specplot_exe += " --outfile " + outname
  
  puts specplot_exe
  
  `#{specplot_exe}`
  
  image_location
end

def run_single_peptide()
  file_prefix = String.random_alphanumeric(16)
  
  input_peptides_file = File.join("public", file_prefix + ".input")
  input_file = File.new(input_peptides_file, "w")
  input_file << params[:peptide]
  input_file.close
  
  output_file_prefix = file_prefix
  output_peptides_file = File.join("public",  output_file_prefix + ".output")
  stdout_peptides_file = File.join("public",  output_file_prefix + ".stdout")
  
  execute_line = ""
  execute_line += "wine ./KineticModel.exe -o " + output_peptides_file + " " + input_peptides_file + " ./example_params.txt > " + stdout_peptides_file
 
  #Thread.new do
  `#{execute_line}`
  #end
  
  file_prefix
end

get '/massanalyzer/api/:peptide' do
  if params[:peptide] == "favicon.ico"
    return "nothing"
  end
  
  output_peptides_file = run_single_peptide()
  output_peptides_file = File.join("public",  output_peptides_file + ".output")
  
  output_file = File.new(output_peptides_file, "r");
  
  render_text = ""
  output_file.each_line { |line| puts "Got #{line.dump}"
                          render_text += line}
  
  render_text
end


get '/massanalyzer/web/:peptide' do
  if params[:peptide] == "favicon.ico"
    return "nothing"
  end
  
  output_prefix = run_single_peptide()
  output_peptides_file = File.join("public",  output_prefix + ".output")
  
  generate_specplot_images(params[:peptide], output_peptides_file, output_prefix+".png")
  output_image_location = "/" + output_prefix+".png"
  
  mv_png_cmd = "mv " + File.join("html",  output_prefix+".png") + " "  + File.join("public",  output_prefix+".png")
  `#{mv_png_cmd}`
  
  puts output_peptides_file
  puts output_image_location
  
  output_file = File.new(output_peptides_file, "r");
  
  @render_text = ""
  output_file.each_line { |line| #puts "Got #{line.dump}"
                          @render_text += line + "<br>\n"}
  
  @image_url = output_prefix+".png"
    
  erb :web_results
end
