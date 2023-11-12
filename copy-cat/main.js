/**
 * copy-cat: Copyright SquidDev 2023
 *
 *
 * @license
 */define(["require","./persist-7dd7de50"],function(e,t){"use strict";var o;let i=()=>t.__awaiter(void 0,void 0,void 0,function*(){return new(yield new Promise((t,o)=>e(["./jszip.min-7c1798d8"],t,o))).default}),r="_812j-G_iconFont "+t.iconFont,n="_812j-G_actionButton "+t.actionButton,s="_812j-G_tinyText",a="_812j-G_active",l="_812j-G_dialogueBox";t.styleInject('html{--color-dark-1:#1e1e1e;--color-dark-2:#202020;--color-dark-3:#292929;--color-dark-4:#3b3b3b;--color-dark-5:#555;--color-light-1:#fff;--color-light-2:#eee;--color-light-3:#e7e7e7;--color-light-4:#ddd;--color-light-5:#ccc;--color-yellow-1:#dede6c}._812j-G_lightTheme{--text-color:var(--color-dark-2);--text-accent:var(--color-dark-4);--bg-color:var(--color-light-1);--bg-file-tree:var(--color-light-2);--bg-file-tree-item:var(--color-light-3);--bg-file-tree-item-highlight:var(--color-light-4);--bg-file-tree-item-highlight-active:var(--color-light-5);--link-color:#03c5c5;--bg-dialogue:var(--color-light-1);--bg-input:var(--color-light-4);--bg-code-block:var(--color-light-5);--bg-button:var(--color-dark-1)}._812j-G_darkTheme{--text-color:var(--color-light-2);--text-accent:var(--color-light-4);--bg-color:var(--color-dark-1);--bg-file-tree:var(--color-dark-2);--bg-file-tree-item:var(--color-dark-3);--bg-file-tree-item-highlight:var(--color-dark-4);--bg-file-tree-item-highlight-active:var(--color-dark-5);--link-color:var(--color-yellow-1);--bg-dialogue:var(--color-dark-2);--bg-input:var(--color-dark-5);--bg-code-block:var(--color-dark-5);--bg-button:var(--color-light-1)}@media (prefers-color-scheme:dark){body._812j-G_lightTheme{--text-color:var(--color-light-2);--text-accent:var(--color-light-4);--bg-color:var(--color-dark-1);--bg-file-tree:var(--color-dark-2);--bg-file-tree-item:var(--color-dark-3);--bg-file-tree-item-highlight:var(--color-dark-4);--bg-file-tree-item-highlight-active:var(--color-dark-5);--link-color:var(--color-yellow-1);--bg-dialogue:var(--color-dark-2);--bg-input:var(--color-dark-5);--bg-button:var(--color-dark-1)}}._812j-G_actionButton{}._812j-G_iconFont{fill:var(--bg-button);}._812j-G_infoDescription{padding:5px 10px}._812j-G_tinyText{color:var(--text-accent);font-size:.8em;font-weight:300}._812j-G_errorView{color:#670000;background-color:#ffb6b6}._812j-G_termLine:before{content:"> "}._812j-G_computerView{height:100%}._812j-G_computerSplit{flex-wrap:nowrap;justify-content:space-between;height:100%;display:flex}._812j-G_terminalView,._812j-G_editorView{background:var(--bg-color);color:var(--text-color);flex-grow:1;flex-shrink:1;overflow:hidden}._812j-G_fileList{background-color:var(--bg-file-tree);color:var(--text-color);scrollbar-width:thin;flex-basis:200px;max-width:200px;font-size:.8em;line-height:1.4em;position:relative;overflow-y:auto}._812j-G_fileTree{margin:0;padding:0;list-style:none}._812j-G_fileEntryHead{cursor:pointer;background-color:var(--bg-file-tree-item);padding:5px 15px}._812j-G_fileComputerControl{background-color:var(--bg-file-tree-item);color:var(--text-color);position:relative}._812j-G_fileComputer{cursor:pointer;background-color:var(--bg-file-tree-item);color:var(--text-color);padding:10px 15px;font-size:1.3em}._812j-G_fileComputerActions{pointer-events:none;justify-content:flex-end;align-items:center;display:flex;position:absolute;inset:0}._812j-G_fileComputerActions ._812j-G_actionButton{pointer-events:all;text-align:center;width:2em;height:2em;margin:5px}._812j-G_fileComputerActions ._812j-G_actionButton:hover{background:#0000001a}._812j-G_fileEntryHead:hover,._812j-G_fileComputer:hover{background:var(--bg-file-tree-item-highlight)}._812j-G_fileEntryHead._812j-G_active,._812j-G_fileComputer._812j-G_active,._812j-G_fileEntryHead._812j-G_active:hover,._812j-G_fileComputer._812j-G_active:hover{background:var(--bg-file-tree-item-highlight-active)}._812j-G_fileEntryName{text-overflow:ellipsis;overflow:hidden}._812j-G_fileEntryIcon{width:1em;padding:0 5px;display:inline-block}._812j-G_fileDropMarker{display:none}._812j-G_fileList._812j-G_dragging ._812j-G_fileDropMarker{pointer-events:none;background:#00000080;flex-direction:column;justify-content:center;display:flex;position:absolute;inset:0}._812j-G_fileDropMarker>span{color:#fff;text-align:center;padding:10px;font-size:2em;line-height:1em}._812j-G_editorPlaceholder{color:#aaa;text-align:center;margin:1em;font-size:3em}._812j-G_infoButtons{z-index:50;position:fixed;bottom:5px;left:5px}._812j-G_infoButtons>button{opacity:.6;padding:0 3px}._812j-G_infoButtons>button:hover{opacity:1}._812j-G_dialogueOverlay{z-index:150;background:#000000b3;position:fixed;inset:0}._812j-G_dialogueBox{box-sizing:border-box;background:var(--bg-dialogue);color:var(--text-color);width:90vw;max-width:800px;max-height:90vh;margin:0 auto;padding:20px;position:relative;top:5vh;overflow-y:scroll}._812j-G_dialogueBox a{color:var(--link-color)}._812j-G_formGroup{flex-wrap:wrap;display:flex}._812j-G_formGroup>label{box-sizing:border-box;flex-basis:50%;padding:10px;font-weight:500}._812j-G_formGroup ._812j-G_tinyText{overflow-wrap:anywhere;color:var(--text-accent);margin:0}._812j-G_formGroup input[type=text],._812j-G_formGroup input[type=number],._812j-G_formGroup select{background-color:var(--bg-input);color:var(--text-color);border-style:none;border-radius:4px;width:100%;margin-top:2px;padding:6px;display:block}._812j-G_formGroup input[type=checkbox]{margin:0 5px 0 0}@media (width<=800px){._812j-G_formGroup>label{flex-basis:100%}}h1,h2,h3,p{color:var(--text-color)}');let d=e=>{let o=t.y("svg",{xmlns:"http://www.w3.org/2000/svg",viewBox:"0 0 1000 1000",class:r},e);return()=>o},c=d(t.y("path",{d:"M571 650q0 -59 -41 -101t-101 -42 -101 42 -42 101 42 101 101 42 101 -42 41 -101zm286 -61v124q0 7 -4 13t-11 7l-104 16q-10 30 -21 51 19 27 59 77 6 6 6 13t-5 13q-15 21 -55 61t-53 39q-7 0 -14 -5l-77 -60q-25 13 -51 21 -9 76 -16 104 -4 16 -20 16h-124q-8 0 -14 -5t-6 -12l-16 -103q-27 -9 -50 -21l-79 60q-6 5 -14 5 -8 0 -14 -6 -70 -64 -92 -94 -4 -5 -4 -13 0 -6 5 -12 8 -12 28 -37t30 -40q-15 -28 -23 -55l-102 -15q-7 -1 -11 -7t-5 -13v-124q0 -7 5 -13t10 -7l104 -16q8 -25 22 -51 -23 -32 -60 -77 -6 -7 -6 -14 0 -5 5 -12 15 -20 55 -60t53 -40q7 0 15 5l77 60q24 -13 50 -21 9 -76 17 -104 3 -16 20 -16h124q7 0 13 5t7 12l15 103q28 9 51 20l79 -59q5 -5 13 -5 7 0 14 5 72 67 92 95 4 5 4 12 0 7 -4 13 -9 12 -29 37t-30 40q15 28 23 54l102 16q7 1 12 7t4 13z"})),h=d(t.y("path",{d:"M571 918v-89q0 -8 -5 -13t-12 -5h-54v-286q0 -8 -5 -13t-13 -5h-178q-8 0 -13 5t-5 13v89q0 8 5 13t13 5h53v179h-53q-8 0 -13 5t-5 13v89q0 8 5 13t13 5h250q7 0 12 -5t5 -13zm-71 -500v-89q0 -8 -5 -13t-13 -5h-107q-8 0 -13 5t-5 13v89q0 8 5 13t13 5h107q8 0 13 -5t5 -13zm357 232q0 117 -57 215t-156 156 -215 58 -216 -58 -155 -156 -58 -215 58 -215 155 -156 216 -58 215 58 156 156 57 215z"})),p=d(t.y("path",{d:"M714 900q0 -15 -10 -25t-25 -11 -25 11 -11 25 11 25 25 11 25 -11 10 -25zm143 0q0 -15 -10 -25t-26 -11 -25 11 -10 25 10 25 25 11 26 -11 10 -25zm72 -125v179q0 22 -16 37t-38 16h-821q-23 0 -38 -16t-16 -37v-179q0 -22 16 -38t38 -16h259l75 76q33 32 76 32t76 -32l76 -76h259q22 0 38 16t16 38zm-182 -318q10 23 -8 39l-250 250q-10 11 -25 11t-25 -11l-250 -250q-17 -16 -8 -39 10 -21 33 -21h143v-250q0 -15 11 -25t25 -11h143q14 0 25 11t10 25v250h143q24 0 33 21z"})),u=d(t.y("path",{d:"M882 650c0 -211 -171 -382 -382 -382s-382 171 -382 382c0 211 171 382 382 382s382 -171 382 -382m-112 -158c0 -62 -50 -112 -112 -112s-111 50 -111 112c0 61 50 112 111 112s112 -51 112 -112m224 -224c0 -62 -50 -112 -112 -112s-112 50 -112 112c0 61 51 112 112 112s112 -50 112 -112",fill:"#000080"})),g=d(t.y("path",{d:"M819 362q16 16 27 42t11 50v642q0 23 -15 38t-38 16h-750q-23 0 -38 -16t-16 -38v-892q0 -23 16 -38t38 -16h500q22 0 49 11t42 27zm-248 -136v210h210q-5 -17 -12 -23l-175 -175q-6 -7 -23 -12zm215 853v-572h-232q-23 0 -38 -16t-16 -37v-233h-429v858h715zm-572 -483q0 -7 5 -12t13 -5h393q8 0 13 5t5 12v36q0 8 -5 13t-13 5h-393q-8 0 -13 -5t-5 -13v-36zm411 125q8 0 13 5t5 13v36q0 8 -5 13t-13 5h-393q-8 0 -13 -5t-5 -13v-36q0 -8 5 -13t13 -5h393zm0 143q8 0 13 5t5 13v36q0 8 -5 13t-13 5h-393q-8 0 -13 -5t-5 -13v-36q0 -8 5 -13t13 -5h393z"})),m=d(t.y("path",{d:"M618 639l-414 415q-11 10 -25 10t-25 -10l-93 -93q-11 -11 -11 -25t11 -25l296 -297 -296 -296q-11 -11 -11 -25t11 -25l93 -93q10 -11 25 -11t25 11l414 414q10 11 10 25t-10 25z"})),f=d(t.y("path",{d:"M939 601l-414 413q-10 11 -25 11t-25 -11l-414 -413q-11 -11 -11 -26t11 -25l93 -92q10 -11 25 -11t25 11l296 296 296 -296q11 -11 25 -11t26 11l92 92q11 11 11 25t-11 26z"})),v=null,y=0,b=(e,t,o,i)=>{y++;let r=i.endsWith(".lua")?"luax":void 0,n=e.editor.createModel(o,r,e.Uri.file(`f${y.toString(16)}/${i}`));return n.updateOptions({trimAutoWhitespace:!0}),n.detectIndentation(!0,2),t.resolved=!0,t.text=n,t.view=null,t},_=e=>{if(e.resolved)return e;let t=b(v,e,e.contents,e.name);return delete e.contents,delete e.mode,t},w=(t,o)=>{if(v)return b(v,{},t,o);let i={resolved:!1,contents:t,name:o,promise:new Promise((t,o)=>e(["./index-ca473d95"],t,o)).then(e=>(v=e,_(i)))};return i};class k extends t.b{constructor(){super(...arguments),this.onResize=()=>{var e;return null===(e=this.editor)||void 0===e?void 0:e.layout()}}componentDidMount(){window.addEventListener("resize",this.onResize),this.setupEditor()}setupEditor(){if(!v){let t=this.editorPromise=new Promise((t,o)=>e(["./index-ca473d95"],t,o)).then(e=>{v=e,this.editorPromise===t&&this.setupEditor()}).catch(e=>console.error(e));return}this.editorPromise=void 0;let t=this.base;for(;t.firstChild;)t.firstChild.remove();this.editor=v.editor.create(t,{roundedSelection:!1,autoIndent:"full"}),this.editor.addAction({id:"save",label:"Save",keybindings:[v.KeyMod.CtrlCmd|v.KeyCode.KeyS],contextMenuGroupId:"file",contextMenuOrder:1.5,run:e=>{var t;this.props.settings.trimWhitespace&&(null===(t=e.getAction("editor.action.trimTrailingWhitespace"))||void 0===t||t.run()),this.props.doSave(e.getValue())}}),this.syncOptions()}componentWillUnmount(){window.removeEventListener("resize",this.onResize),this.editor&&(_(this.props.model).view=this.editor.saveViewState(),this.props.doSave(this.editor.getValue()),this.editor.dispose())}componentWillUpdate(){this.editor&&(_(this.props.model).view=this.editor.saveViewState())}componentDidUpdate(){this.editor&&this.syncOptions()}syncOptions(){if(!this.editor)return;let e=this.props.settings,t=_(this.props.model);this.editor.setModel(t.text),t.view&&this.editor.restoreViewState(t.view),this.editor.updateOptions({renderWhitespace:e.showInvisible?"boundary":"none"}),null!==v&&v.editor.setTheme(e.darkMode?"vs-dark":"vs"),this.props.focused&&this.editor.focus()}render(){return t.y("div",{class:"_812j-G_editorView"},v?void 0:t.y("div",{class:"_812j-G_editorPlaceholder"},"Loading..."))}}let j=(e,o,i)=>o?i?t.y(f,null):t.y(m,null):e.endsWith(".lua")?t.y(u,null):t.y(g,null);class x extends t.b{shouldComponentUpdate({entry:e,depth:t,opened:o},{expanded:i}){return e!==this.props.entry||t!==this.props.depth||o!==this.props.opened||i!==this.state.expanded}render({computer:e,entry:o,name:i,path:r,depth:n,opened:s,open:l},{expanded:d}){return t.y("li",null,t.y("div",{class:`_812j-G_fileEntryHead ${s===r?a:""}`,style:`padding-left: ${n}em`,onClick:o.isDirectory()?()=>this.setState({expanded:!d}):()=>l(r,o)},t.y("span",{class:"_812j-G_fileEntryIcon"},j(i,o.isDirectory(),null!=d&&d)),t.y("span",{class:"_812j-G_fileEntryName"},i)),d?t.y(G,{computer:e,entry:o,path:r,depth:n,opened:s,open:l}):null)}}class G extends t.b{constructor(){super(...arguments),this.listener=()=>this.setState({children:this.props.entry.getChildren()})}shouldComponentUpdate({entry:e,depth:t,opened:o},{children:i}){return e!==this.props.entry||t!==this.props.depth||i!==this.state.children||o!==this.props.opened}render({computer:e,entry:o,path:i,depth:r,opened:n,open:s},{children:a}){if(!o.doesExist())return"";let l=(null!=a?a:o.getChildren()).map(o=>{let a=t.joinName(i,o),l=e.getEntry(a);return{name:o,dir:l.isDirectory(),node:t.y(x,{computer:e,entry:l,path:a,name:o,depth:void 0===r?0:r+1,opened:n,open:s})}});return l.sort((e,t)=>e.dir!==t.dir?e.dir?-1:1:e.name<t.name?-1:1),t.y("ul",{class:"_812j-G_fileTree"},l.map(e=>e.node))}componentDidMount(){this.props.entry.getSemaphore().attach(this.listener)}componentWillUnmount(){this.props.entry.getSemaphore().detach(this.listener)}componentDidUpdate({entry:e}){this.props.entry!==e&&(this.props.entry.getSemaphore().detach(this.listener),e.getSemaphore().attach(this.listener))}}let C=e=>t.__awaiter(void 0,void 0,void 0,function*(){let o=yield i(),r=[""];for(;;){let i=r.pop();if(void 0===i)break;let n=e.getEntry(i);if(n){if(n.isDirectory())for(let e of(""!==i&&o.folder(i),n.getChildren()))r.push(t.joinName(i,e));else o.file(i,n.getContents().buffer)}}return o.generateAsync({type:"blob"})}),q=(e,t)=>{for(let o in e.files)if(Object.prototype.hasOwnProperty.call(e.files,o)&&!o.startsWith(t+"/"))return!1;return!0};class S extends t.b{constructor(e,o){var i;super(e,o),this.openFile=(e,t)=>{if(t.isDirectory())return;let o=this.state.openFiles.get(t);if(void 0===o){let i=w(t.getStringContents(),e),r=()=>{t.doesExist()||(i.resolved&&i.text.dispose(),t.getSemaphore().detach(r),this.state.openFiles.delete(t))};o={model:i,monitor:r},this.state.openFiles.set(t,o),t.getSemaphore().attach(r)}else{let e=o.model,i=t.getStringContents();e.resolved?i!==e.text.getValue()&&e.text.setValue(i):e.contents=i}this.setState({activeFile:{file:t,path:e,model:o.model}})},this.openComputer=()=>{this.setState({activeFile:null})},this.saveZip=e=>{e.preventDefault(),e.stopPropagation(),C(this.state.computer).then(e=>t.saveBlob("computer","zip",e)).catch(e=>console.error(e))},this.startDrag=e=>{e.preventDefault(),this.state.dragging||this.setState({dragging:!0})},this.stopDrag=()=>{this.setState({dragging:!1})},this.dropFile=e=>{if(e.preventDefault(),this.setState({dragging:!1}),e.dataTransfer){if(e.dataTransfer.items){let t=e.dataTransfer.items;for(let e=0;e<t.length;e++){let o=t[e];"file"===o.kind&&this.addFile(o.getAsFile())}}else{let t=e.dataTransfer.files;for(let e=0;e<t.length;e++)this.addFile(t[e])}}};let r=new t.TerminalData,n=new t.Semaphore,s=new t.ComputerAccess(new t.StoragePersistence(0),r,n,(e,t)=>this.setState({label:e,on:t}));for(let e of window.location.search.substring(1).split("&")){let t;let[o,r]=e.split("=");if("startup"===o){try{t=atob(r)}catch(e){console.error(e);break}t=t.replace(/(\\|\n|")/g,"\\$1").replace("\r","\\r").replace("\x00","\\0"),null===(i=s.createFile("startup.lua").value)||void 0===i||i.setContents(`
fs.delete("startup.lua")
local fn, err = load("${t}", "@startup.lua", nil, _ENV)
if not fn then error(err, 0) end
fn()`)}}this.setState({terminal:r,terminalChanged:n,computer:s,activeFile:null,openFiles:new Map,id:0,on:!1,label:s.getLabel(),dragging:!1})}componentDidMount(){this.state.computer.start(this.props.computerSettings)}componentWillUnmount(){for(let[e,{model:t,monitor:o}]of(this.state.computer.shutdown(),this.state.openFiles))t.resolved&&t.text.dispose(),e.getSemaphore().detach(o)}shouldComponentUpdate({focused:e,settings:t},{id:o,label:i,on:r,activeFile:n,dragging:s}){return e!==this.props.focused||t!==this.props.settings||o!==this.state.id||i!==this.state.label||r!==this.state.on||n!==this.state.activeFile||s!==this.state.dragging}render({settings:e,focused:o},{terminal:i,terminalChanged:r,computer:s,activeFile:l,id:d,label:c,on:h,dragging:u}){return t.y("div",{class:"_812j-G_computerView"},t.y("div",{class:"_812j-G_computerSplit"},t.y("div",{class:`_812j-G_fileList ${u?"_812j-G_dragging":""}`,onDragOver:this.startDrag,onDragLeave:this.stopDrag,onDrop:this.dropFile},t.y("div",{class:"_812j-G_fileComputerControl"},t.y("div",{class:`_812j-G_fileComputer ${null==l?a:""}`,onClick:this.openComputer},d?`Computer #${d}`:"Computer"),t.y("div",{class:"_812j-G_fileComputerActions"},t.y("button",{class:n,type:"button",onClick:this.saveZip,title:"Download all files as a zip"},t.y(p,null)))),t.y(G,{computer:s,entry:s.getEntry(""),path:"",opened:null===l?null:l.path,open:this.openFile}),t.y("div",{class:"_812j-G_fileDropMarker"},t.y("span",null,"Upload to your computer!"))),null==l?t.y("div",{class:"_812j-G_terminalView"},t.y(t.Terminal,{terminal:i,changed:r,focused:o,computer:s,font:e.terminalFont,id:d,label:c,on:h})):t.y(k,{model:l.model,settings:e,focused:o,doSave:e=>l.file.setContents(e)})))}addOneFile(e,t){let o=e.lastIndexOf("."),i=o>0?e.substring(0,o):e,r=o>0?e.substring(o):"",n=this.state.computer;for(let o=0;o<100;o++){let s=0===o?e:`${i}.${o}${r}`;if(n.getEntry(s))continue;let a=this.state.computer.createFile(s);if(a.value){a.value.setContents(t);return}}console.warn(`Cannot write contents of ${e}.`)}addFile(e){if(e.name.endsWith(".zip"))i().then(o=>t.__awaiter(this,void 0,void 0,function*(){let t;yield o.loadAsync(e);let i=this.state.computer,r=e.name.substring(0,e.name.length-4);for(let e=0;e<100;e++){if(t=0===e?r:`${r}.${e}`,i.getEntry(t))continue;let o=this.state.computer.createDirectory(t);if(o.value)break}let n=q(o,r)?r.length+1:0;for(let e in o.files){if(!Object.prototype.hasOwnProperty.call(o.files,e)||e.length===n)continue;let r=`${t}/${e.substr(n)}`,s=o.files[e];s.dir?(r.endsWith("/")&&(r=r.substring(0,r.length-1)),i.createDirectory(r)||console.warn(`Cannot create directory ${r}.`)):this.addOneFile(r,(yield s.async("arraybuffer")))}})).catch(e=>console.error(e));else{let t=new FileReader;t.onload=()=>this.addOneFile(e.name,t.result),t.readAsArrayBuffer(e)}}}t.y("div",{class:"_812j-G_infoDescription"},t.y("p",null,"Think you've found a bug? Have a suggestion? Why not put it on ",t.y("a",{href:"https://github.com/SquidDev-CC/copy-cat",title:"The GitHub repository"},"the GitHub repo"),"?"));let F=()=>t.y("div",{class:l},t.y("h2",null,"About"),t.y("p",null,"Copy Cat is a web emulator for the popular Minecraft mod ",t.y("a",{href:"https://github.com/cc-tweaked/CC-Tweaked",target:"_blank",title:"CC: Tweaked's source code"},"CC: Tweaked")," (based on ComputerCraft by Dan200). Here you can play with a ComputerCraft computer, write and test programs and experiment to your heart's desire, without having to leave your browser!"),t.y("p",null,"However, due to the limitations of Javascript, some functionality may not be 100% accurate (most notably, that to do with HTTP and filesystems). For even closer emulation, I'd recommend ",t.y("a",{href:"https://emux.cc/",target:"_blank",title:"The CCEmuX emulator"},"CCEmuX"),"."),t.y("p",null,"If you need help writing a program, I'd recommend checking out the ",t.y("a",{href:"https://forums.computercraft.cc/",target:"_blank",title:"The CC: Tweaked forums"},"forums")," or ",t.y("a",{href:"https://discord.computercraft.cc",title:"The Minecraft Computer Mods Discord",target:"_blank"},"Discord"),". ",t.y("a",{href:"https://tweaked.cc",target:"_blank",title:"The CC: Tweaked wiki"},"The CC: Tweaked wiki")," may also be a good source of documentation."),t.y("p",null,"Of course, this emulator is sure to have lots of bugs and missing features. If you've found a problem, why not put it on ",t.y("strong",null,t.y("a",{href:"https://github.com/SquidDev-CC/copy-cat/issues",title:"The Copy Cat GitHub issue tracker"},"the GitHub repo")),"?"),t.y("h3",null,"Credits"),t.y("p",null,"Copy Cat would not be possible without the help of several Open Source projects."),t.y("ul",null,t.y("li",null,t.y("a",{href:"https://github.com/konsoletyper/teavm",target:"_blank"},"TeaVM"),": Apache 2.0"),t.y("li",null,t.y("a",{href:"https://github.com/google/guava",target:"_blank"},"Google Guava"),": Apache 2.0"),t.y("li",null,t.y("a",{href:"https://github.com/apache/commons-lang",target:"_blank"},"Apache Commons Lang"),": Apache 2.0, Copyright 2001-2018 The Apache Software Foundation"),t.y("li",null,t.y("a",{href:"https://github.com/SquidDev/Cobalt",target:"_blank"},"Cobalt/LuaJ"),": MIT, Copyright (c) 2009-2011 Luaj.org. All rights reserved., modifications Copyright (c) 2015-2016 SquidDev"),t.y("li",null,t.y("a",{href:"https://github.com/cc-tweaked/CC-Tweaked",target:"_blank"},"CC: Tweaked"),": ComputerCraft Public License"),t.y("li",null,t.y("a",{href:"https://github.com/FortAwesome/Font-Awesome/",target:"_blank"},"Font Awesome"),": CC BY 4.0"),t.y("li",null,"Numerous Javascript libraries. A full list can be found ",t.y("a",{href:"dependencies.txt",target:"_blank"},"in the dependencies list")," or at the top of any Javascript file.")),t.y("pre",null,`This product includes software developed by Alexey Andreev (http://teavm.org).

This product includes software developed by The Apache Software Foundation (http://www.apache.org/).

This product includes software developed by Joda.org (http://www.joda.org/).`));class D{constructor(){this.data={};let e=t.get("settings");if(null!==e)try{this.data=JSON.parse(e)}catch(e){console.error("Cannot read settings",e)}}get(e){return e.id in this.data?this.data[e.id]:e.def}set(e,o){this.get(e)!==o&&(this.data[e.id]=o,e.changed(o),t.set("settings",JSON.stringify(this.data)))}}class T{constructor(e,t,o){this.properties=[],this.name=e,this.description=t,this.store=o}add(e){this.properties.push(e);let t=this.store.get(e);return t!==e.def&&e.changed(t),e}addString(e,t,o,i,r){return this.add({type:"string",id:e,name:t,description:i,def:o,changed:r})}addBoolean(e,t,o,i,r){return this.add({type:"boolean",id:e,name:t,description:i,def:o,changed:r})}addOption(e,t,o,i,r,n){return this.add({type:"option",id:e,name:t,description:r,choices:i,def:o,changed:n})}addInt(e,t,o,i,r,n,s){return this.add({type:"int",id:e,name:t,description:n,def:o,min:i,max:r,changed:s})}}function z(e,t,o){return i=>{let r=o(i.target);void 0!==r&&e.set(t,r)}}let M=e=>e.value,O=e=>{let t=parseInt(e.value,10);return Number.isNaN(t)?void 0:t},E=e=>e.checked,A=(e,t)=>o=>{for(let{key:e}of t)if(e===o.value)return e;return e},B=({store:e,configGroups:o})=>t.y("div",{class:l},t.y("h2",null,"Settings"),o.map(({name:o,description:i,properties:r})=>[t.y("h3",null,o),i?t.y("p",{class:s},i):null,t.y("div",{class:"_812j-G_formGroup"},r.map(o=>{switch(o.type){case"string":return t.y("label",null,o.name,t.y("input",{type:"text",value:e.get(o),onChange:z(e,o,M)}),t.y("p",{class:s},o.description));case"int":return t.y("label",null,o.name,t.y("input",{type:"number",value:e.get(o),min:o.min,max:o.max,step:1,onChange:z(e,o,O)}),t.y("p",{class:s},o.description));case"boolean":return t.y("label",null,t.y("input",{type:"checkbox",checked:e.get(o),onInput:z(e,o,E)}),o.name,t.y("p",{class:s},o.description));case"option":return t.y("label",null,o.name,t.y("select",{value:e.get(o),onInput:z(e,o,A(o.def,o.choices))},o.choices.map(({key:e,value:o})=>t.y("option",{value:e},o))),t.y("p",{class:s},o.description))}}))])),I=(...e)=>e.filter(e=>!!e).join(" ");class V extends t.b{constructor(e,o){super(e,o),this.openSettings=()=>{this.setState({dialogue:({settingStorage:e,configGroups:o})=>t.y(B,{store:e,configGroups:o})})},this.closeDialogueClick=e=>{e.target===e.currentTarget&&this.setState({dialogue:void 0})},this.computerVDom=({settings:e,dialogue:o})=>t.y(S,{settings:e,focused:void 0===o,computerSettings:this.configFactory}),this.configFactory=(e,t)=>{let o=this.state.configGroups.find(t=>t.name===e);if(o)return o.description!==t&&console.warn(`Different descriptions for ${e} ("${t}" and "${o.description}")`),o;let i=new T(e,t,this.state.settingStorage);return this.setState(e=>({configGroups:[...e.configGroups,i]})),i}}componentWillMount(){let e=new D,o=new T("Editor","Configure the built-in editor",e),i=new T("Terminal","Configure the terminal display",e),r={settingStorage:e,configGroups:[o,i],settings:{showInvisible:!0,trimWhitespace:!0,darkMode:!1,terminalFont:t.termFont},currentVDom:this.computerVDom};this.setState(r),o.addBoolean("editor.invisible","Show invisible",r.settings.showInvisible,"Show invisible characters, such as spaces and tabs.",e=>this.setState(t=>({settings:Object.assign(Object.assign({},t.settings),{showInvisible:e})}))),o.addBoolean("editor.trim_whitespace","Trim whitespace",r.settings.trimWhitespace,"Trim whitespace from files when saving.",e=>this.setState(t=>({settings:Object.assign(Object.assign({},t.settings),{trimWhitespace:e})}))),o.addBoolean("editor.dark","Dark mode",r.settings.darkMode,"Enables dark mode.",e=>{this.setState(t=>({settings:Object.assign(Object.assign({},t.settings),{darkMode:e})}))});let n={standard:t.termFont,hd:t.termFontHd,[t.termFontHd]:t.termFontHd,"term_font_hd.png":t.termFontHd,[t.termFont]:t.termFont,"term_font.png":t.termFont};i.addOption("terminal.font","Font","standard",[{key:"standard",value:"Standard font"},{key:"hd",value:"High-definition font"}],"Which font the we should use within the terminal",e=>this.setState(o=>({settings:Object.assign(Object.assign({},o.settings),{terminalFont:n[e]||t.termFontHd})})))}shouldComponentUpdate(e,t){return this.state.currentVDom!==t.currentVDom||this.state.dialogue!==t.dialogue||this.state.settings!==t.settings}render(e,o){return t.y("div",{class:I("container",o.settings.darkMode?"_812j-G_darkTheme":"_812j-G_lightTheme")},o.currentVDom(o),t.y("div",{class:"_812j-G_infoButtons"},t.y("button",{class:n,title:"Configure how the emulator behaves",type:"button",onClick:this.openSettings},t.y(c,null)),t.y("button",{class:n,title:"Find out more about the emulator",type:"button",onClick:()=>this.setState({dialogue:()=>t.y(F,null)})},t.y(h,null))),o.dialogue?t.y("div",{class:"_812j-G_dialogueOverlay",onClick:this.closeDialogueClick},o.dialogue(o)):"")}}{requirejs.config({paths:{vs:"https://cdn.jsdelivr.net/npm/monaco-editor@0.44.0/min/vs"}}),window.MonacoEnvironment={getWorkerUrl:(e,t)=>`data:text/javascript;charset=utf-8,${encodeURIComponent(`
      self.MonacoEnvironment = {
        baseUrl: "https://cdn.jsdelivr.net/npm/monaco-editor@0.44.0/min/"
      };
      importScripts("https://cdn.jsdelivr.net/npm/monaco-editor@0.44.0/min/vs/base/worker/workerMain.js");
    `)}`};let e=document.getElementById("page");t.B(t.y(V,null),e,null!==(o=e.lastElementChild)&&void 0!==o?o:void 0)}});
