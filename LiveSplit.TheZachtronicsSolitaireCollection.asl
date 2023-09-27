state("The Zachtronics Solitaire Collection") {}

startup
{
    const string GAMEPATH = @"\My Games\The Zachtronics Solitaire Collection\";
    const string FILE = "log.dat";

    print("startup");

    string directory = null;

    string documentsPath = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
    string gamePath = documentsPath + GAMEPATH;

    if (Directory.Exists(gamePath)) {
        string[] steamuserdirs = Directory.GetDirectories(gamePath, "*", SearchOption.TopDirectoryOnly);
        foreach (string steamuserdir in steamuserdirs) {
            directory = steamuserdir;
        }
    }
    
    if (directory != null) {
        print("Found game directory: \n" + directory);
    } else {
        print("Couldn't find game directory");
    }

    string path = directory + "\\" + FILE;
    
    vars.reader = null;

    // open log if it already exists
    // and read away any old lines
    if (File.Exists(path))
    {
        var stream = File.Open(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete);
        vars.reader = new StreamReader(stream);

        vars.reader.ReadToEnd();
    }

    // setup a watcher to know when the game creates and deletes log file
    var watcher = new FileSystemWatcher(directory, FILE);

    watcher.Created += (s, e) => {
        print("created");
        vars.reader = new StreamReader(File.Open(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete));
    };
    
    watcher.Deleted += (s, e) => {
        print("deleted");
        vars.reader.Close();
        vars.reader = null;
    };
    watcher.EnableRaisingEvents = true;

    vars.watcher = watcher;

    // gametime tracking variable
    // set to true when a new game of any solitaire is started
    // set to false when any of them is solved
    vars.isSolving = false;

    // how many splits have been made
    // if you haven't finished a solve and you restart, the timer will reset
    vars.splitsMade = 0;
}

update
{
    if (vars.reader == null)
        return false;

    vars.line = vars.reader.ReadLine();

    if (vars.line != null) {
        print(vars.line);

        if (vars.line.Contains("Started")) {
            vars.isSolving = true;
        }

        if (vars.line.Contains("Won")) {
            vars.isSolving = false;
        }
    }
}

split {
    if (vars.line == null)
        return false;

    if (vars.line.Contains("Won")) {
        vars.splitsMade++;
        print(vars.splitsMade.ToString());

        return true;
    } 
}

start {
    if (vars.line == null)
        return false;
    
    if (vars.line.Contains("Started")) {
        vars.splitsMade = 0;
        print(vars.splitsMade.ToString());

        return true;
    }
}

reset {
    if (vars.line == null)
        return false;
    
    if (vars.splitsMade == 0 && vars.line.Contains("Started")) {
        return true;
    }
}

isLoading {
    return !vars.isSolving;
}

shutdown {
    if (vars.reader != null) {
        vars.reader.Close();
        vars.reader = null;
    }

    if (vars.watcher != null) {
        vars.watcher.Dispose();
        vars.watcher = null;
    }
}