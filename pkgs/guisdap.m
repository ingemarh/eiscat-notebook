homedir=getenv('HOME');
if ~exist(fullfile(homedir,'gup'),'dir'), mkdir(fullfile(homedir,'gup')), end
if ~exist(fullfile(homedir,'gup','mygup'),'dir'), mkdir(fullfile(homedir,'gup','mygup')), end
if ~exist(fullfile(homedir,'gup','results'),'dir'), mkdir(fullfile(homedir,'gup','results')), end
if ~exist(fullfile(homedir,'tmp'),'dir'), mkdir(fullfile(homedir,'tmp')), end
addpath([homedir,'/gup/mygup'],'/opt/guisdap/anal','/opt/guisdap/init')
clear homedir
startup
