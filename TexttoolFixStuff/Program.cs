using System;
namespace CSharpStuff{
    class Progam{
        static void Main(string[] args){
            string path = @"input.txt";
            
                string[] lines = File.ReadAllLines(path);
                for(int i = 0; i<lines.Length; i++){
                    if(lines[i].Contains("-->")){
                        lines[i] = lines[i].Replace("-->","");
                    }
                }
                File.WriteAllLines(@"output.txt",lines);
            
        }
    }
}
