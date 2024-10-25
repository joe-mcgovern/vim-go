command! -nargs=0 GoTest :call GoTest()
command! -nargs=* GoRun :call GoRun(<q-args>)
command! -nargs=0 GoNewTest :call NewSimpleGoTest()
command! -nargs=0 GoYankPackage :call YankGoPackage()

" gtp -> go test package
nnoremap <buffer> <leader>gtp :GoTest<CR>

" grp -> go run package
nnoremap <buffer> <leader>grp :GoRun<CR>

" gnt -> go new test
nnoremap <buffer> <leader>gnt :GoNewTest<CR>

" gyp -> go yank package
nnoremap <buffer> <leader>gyp :GoYankPackage<CR>


func GoTest(filter)
  let pieces = s:getProjectPaths()
  let pathToProject = pieces[0]
  let pathWithinProject = pieces[1]
  let target = "./" . pathWithinProject . "/..."
  let cmd = "go test " . target
  if len(a:filter) > 0
    let cmd = "go test -run '" . a:filter . "' " . target
  endif
  let promptResult = confirm("Run test? " . cmd, " &Yes\n&No")
  if promptResult ==# 1
    execute ":Start -wait=always -dir=" . pathToProject . " go test " . target
  elseif promptResult
    return
  endif
endfunc

func GoRun(args)
  let pieces = s:getProjectPaths()
  let pathToProject = pieces[0]
  let pathWithinProject = pieces[1]
  let target = "./" . pathWithinProject
  let argsToUse = get(b:, "go_run_args", "")
  if len(a:args) > 0
    let argsToUse = a:args
  endif
  if len(argsToUse) > 0
    let target = target . " " . a:args
  endif
  let cmd = "go test " . target
  let promptResult = confirm("Run binary? " . cmd, " &Yes\n&No")
  if promptResult ==# 1
    execute ":Start -wait=always -dir=" . pathToProject . " go run " . target
  elseif promptResult
    return
  endif
endfunc

func GoTestNearest()
  let prevPos = getcurpos()
  defer setpos('.', prevPos)
  " b flag indicates we are doing a backwards (e.g. upwards) search
  " c flag indicates that a match under the cursor is fine too
  let searchPattern = '^func\( (.*)\)\? \(Test.*\)('
  let line = search(searchPattern, 'bc')
  if line ==# 0
    " if we can't find it above us, let's look beneath
    let downwardLine = search(searchPattern)
    if downwardLine ==# 0
      " if there are no matches, see if the user wants to run the suite
      " against the whole package
      s:confirmRunSuite()
      return
    endif
    let line = downwardLine
  endif
  let lineContent = getline(line)
  let testName = s:getTestFilterFromLine(lineContent)
  if testName ==# ""
    s:confirmRunSuite()
    return
  endif
  call GoTest(testName)
endfunc

func s:confirmRunSuite()
  let promptResult = confirm("Could not find nearest test, run entire suite?", "&Yes\n&No")
  if promptResult ==# 1
    GoTestPackage()
  else
    echom "canceled test request"
    return
  endif
endfunc

" Code below this is to support adding a simple binding to generate
" boilerplate for a go table-driven test
"
let s:goTestLines =<< END
func TestFoo(t *testing.T) {
	testCases := []struct {
		name string
	}{
		{
			name: "foo",
		},
	}
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
		})
	}
}
END


function NewSimpleGoTest()
  let testName = input("Test name:", "")
  let lines = copy(s:goTestLines)
  let lines[0] = substitute(lines[0], "TestFoo", "Test" . testName, "")
  call append(line('.'), lines)
endfunction

function YankGoPackage()
  " this is the absolute path, without the filename
  let path = expand("%:p:h")
  let pieces = split(path, "/")
  let ghIndex = index(pieces, "github.com")
  if ghIndex ==# -1
    let ghIndex = 0
  endif
  let pieces = pieces[ghIndex:len(pieces)]
  let result = join(pieces, "/")
  call setreg("*", result)
  echom result
endfunction

func s:getTestFilterFromLine(line)
  let words = split(a:line, " ")
  let suiteName = ""
  let testName = ""
  " get the suite name if there is one
  if len(words) >= 3
    if words[1] =~# "^(" && words[2] =~# "^\*.*)"
      let wordWithoutStar = substitute(words[2], "*", "", "")
      let suiteName = substitute(wordWithoutStar, ")", "", "")
    endif
  endif
  " get the test name
  for word in words
    if word =~# "^Test.*("
      let parsedWord = split(word, "(")
      let testName = parsedWord[0]
      break
    endif
  endfor
  if len(suiteName) > 0
    return suiteName . "/". testName
  endif
  return testName
endfunc

" getProjectPaths returns a two-element array where the first element is the
" path to the project directory (e.g. where the go command should be run from)
" and the second element is the path to the package within the project (what
" the go command should be running against)
func s:getProjectPaths()
  let path = expand("%:p:h")
  let parts = split(path, "/")
  let home = getenv("HOME")
  let currentIndex = len(parts) - 1
  while currentIndex >= 0
    let currentParts = parts[0 : currentIndex]
    let pathSubset = "/" . join(currentParts, "/")
    if pathSubset ==# home
      break
    endif
    if isdirectory(pathSubset . "/.git")
      let remainingParts = parts[currentIndex + 1: len(parts) -1 ]
      let remainingPath = join(remainingParts, "/")
      return [pathSubset, remainingPath]
    endif
    let currentIndex -= 1
  endwhile
  return ["", ""]
endfunc
