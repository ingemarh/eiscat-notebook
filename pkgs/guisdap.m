homedir=getenv('HOME');
if ~exist(fullpath(homedir,'gup'),'dir'), mkdir(fullpath(homedir,'gup')), end
if ~exist(fullpath(homedir,'gup','mygup'),'dir'), mkdir(fullpath(homedir,'gup','mygup')), end
if ~exist(fullpath(homedir,'gup','results'),'dir'), mkdir(fullpath(homedir,'gup','results')), end
if ~exist(fullpath(homedir,'tmp'),'dir'), mkdir(fullpath(homedir,'tmp')), end
addpath([homedir,'/gup/mygup'],'/opt/guisdap/anal','/opt/guisdap/init')
startup
