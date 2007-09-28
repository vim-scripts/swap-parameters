""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" swap_parameters.vim - swap parameters - fun(arg2, arg1, arg3)
" Author: Kamil Dworakowski <kamil-at-dworakowski.name>
" Version: 1.0
" Last Change: 2007-09-28 
" URL: http://blog.kamil.dworakowski.name
" Requires: Python and Vim compiled with +python option
" Licence: This script is released under the Vim License.
" Installation: Put into plugin directory
" Basic Usecase: Place the cursor inside the parameter you want to swap
" with the next one, and press gs
" Description:
"
" It is a versatile script to swap parameters of a function
" or, generally speaking, any coma seperated list of elements.
"
" key bindings (normal mode):
" [count]gs -- where count defaults to 1 -- swap the argument under
"              the cursor with the [count] next one
" [count]gS -- swap with the previous
"
" Below are exaples of what happens after pressing gr (equivalent to 1gr).
" On each line the lefthand side shows the line before typing gr, and
" the righthand side shows the effect. The cursor position is depicted
" with || symbols. par|m|1 means that the cursor is on the character m.
" 
"                   fun(par|m|1, parm2)                    fun(parm2, parm|1|)
"                 fun(par|m|1(), parm2)                  fun(parm2, parm1(|)|)
"                 fun(parm1(|)|, parm2)                  fun(parm2, parm1(|)|)
"         fun(parm|1|(arg,arg2), parm2)          fun(parm2, parm1(arg,arg2|)|)
"         fun(parm1|(|arg,arg2), parm2)          fun(parm2, parm1(arg,arg2|)|)
"         fun(parm1(arg,arg2|)|, parm2)          fun(parm2, parm1(arg,arg2|)|)
"        fun(parm1(arg, arg2|)|, parm2)         fun(parm2, parm1(arg, arg2|)|)
"               fun(arg1, ar|g|2, arg3)                fun(arg1, arg3, arg|2|)
"                   array[a|r|g1, arg2]                    array[arg2, arg|1|]
"                 fun(par|m|1[], parm2)                  fun(parm2, parm1[|]|)
"                 fun(parm1[|]|, parm2)                  fun(parm2, parm1[|]|)
"                 fun(par|m|1, array[])                  fun(array[], parm|1|)
"                            fun(|a|,b)                             fun(b,|a|)
"                      [(p1, p2|)|, p3]                       [p3, (p1, p2|)|]
"
"
" The following lines demonstrate using gS (swap with previous).
"
"                   fun(parm2, par|m|1)                    fun(|p|arm1, parm2)
"                 fun(parm2, par|m|1())                  fun(|p|arm1(), parm2)
"                 fun(parm2, parm1(|)|)                  fun(|p|arm1(), parm2)
"         fun(parm2, parm|1|(arg,arg2))          fun(|p|arm1(arg,arg2), parm2)
"         fun(parm2, parm1|(|arg,arg2))          fun(|p|arm1(arg,arg2), parm2)
"         fun(parm2, parm1(arg,arg2|)|)          fun(|p|arm1(arg,arg2), parm2)
"        fun(parm2, parm1(arg, arg2|)|)         fun(|p|arm1(arg, arg2), parm2)
"               fun(arg1, ar|g|2, arg3)                fun(|a|rg2, arg1, arg3)
"               fun(arg1, arg2, ar|g|3)                fun(arg1, |a|rg3, arg2)
"                   array[arg2, a|r|g1]                    array[|a|rg1, arg2]
"                 fun(parm2, par|m|1[])                  fun(|p|arm1[], parm2)
"                 fun(parm2, parm1[|]|)                  fun(|p|arm1[], parm2)
"                 fun(array[], par|m|1)                  fun(|p|arm1, array[])
"                            fun(b,|a|)                             fun(|a|,b)
"
"
" The above exaples are autogenerated from the tests.
"
" A useful, however unexpected by the author, feature of this script is that
" on pressing j to move cursor to the line below the column of the cursor is
" restored to the position before the swap. This allows for streamlined
" swaping of parameters in the case like this:
"
" fun(arg2, blah)
" fun(arg2, blahble)
" fun(arg2, blahblahblah)
"
" You would put cursor on arg2, and the gsjgsjgs
"
" 
" This script is written in python. Therefore it needs
" vim copiled with +python option, as well as python installed
" in the system. Sorry for those of you who don't have it
" already installed.
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if !has('python')
    s:ErrMsg( "Error: Required vim compiled with +python" )
    finish
endif


function! SwapParams(directionName)
python << EOF
leftBrackets = ['[', '(']
rightBrackets = [']', ')']

class Direction(object):
    def __init__(self, line, col):
        self.line = line
        self.col = col
        self.length = len(line)

    def withinBounds(self):
        return 0 <= self.col <= self.length-1

    def isOnOpenBracket(self):
        return self.isOpenBracket(self.current())

    def isOnCloseBracket(self):
        return self.isCloseBracket(self.current())

    def isOpenBracket(self, char):
        return char in self.openingBrackets

    def isCloseBracket(self, char):
        return char in self.closingBrackets

    def current(self):
        return self.line[self.col]

    def moveToNext(self):
        self.col = self.next(self.col)

class RightwardDirection(Direction):
    openingBrackets = leftBrackets
    closingBrackets = rightBrackets
    def next(self, col):
        return col+1

    def prev(self, col):
        return col-1
    
    def oposite(self):
        return LeftwardDirection(self.line, self.col)

    def crumble(self, pos):
        part = self.line[0:pos+1]
        self.line = self.line[pos+1:]
        self.col -= pos + 1
        return part

    def join(self, crumbles):
        cookie = ""
        length = 0
        for crumble in crumbles:
            cookie = cookie + crumble
            length += len(crumble)
        self.col += length
        self.line = cookie + self.line
        return self.line

class LeftwardDirection(Direction):
    openingBrackets = rightBrackets
    closingBrackets = leftBrackets

    def next(self, col):
        return col-1

    def prev(self, col):
        return col+1

    def oposite(self):
        return RightwardDirection(self.line, self.col)

    def crumble(self, pos):
        part = self.line[pos:]
        self.line = self.line[0:pos]
        self.col = min(self.col, pos)
        return part

    def join(self, crumbles):
        cookie = ""
        length = 0
        for crumble in reversed(crumbles):
            cookie = cookie + crumble
            length += len(crumble)
        self.line = self.line + cookie 
        return self.line


def pairBracket(direction):
    if direction.isOnCloseBracket():
        direction = direction.oposite()

    direction.moveToNext()

    while direction.withinBounds():
        if direction.isOnCloseBracket():
            return direction.col
        if direction.isOnOpenBracket():
            pairBracket(direction)
        direction.moveToNext()

    return direction.col


def SwapParms(direction):
    def findOneOf(chars,direction):
        while direction.withinBounds():
            if direction.isOnOpenBracket():
                x = pairBracket(direction)
                direction.col = x
            elif direction.current() in chars:
                return direction.col
            direction.moveToNext()
        raise "didn't find any of the", chars

    if direction.isOnOpenBracket():
        oposite = direction.oposite()
        oposite.moveToNext()
        start1 = findOneOf(direction.openingBrackets+[','],oposite)
        direction.col = start1
    elif direction.isOnCloseBracket():
        oposite = direction.oposite()
        oposite.col = oposite.next(pairBracket(oposite))
        start1 = findOneOf(direction.openingBrackets+[','],oposite) 
        direction.col = start1
    else:

        start1 = findOneOf(direction.openingBrackets+[','], direction.oposite())

    direction.col = start1
    direction.moveToNext()
    if direction.current() == ' ':
        direction.moveToNext()

    prefix_crumble = direction.crumble(direction.prev(direction.col))

    stop1 = findOneOf(direction.closingBrackets + [','], direction)

    inner2 = direction.prev(stop1)
    if direction.line[inner2] == ' ':
        inner2 = direction.prev(inner2)
    arg1_crumble = direction.crumble(inner2)

    if direction.line[direction.next(direction.col)] == ' ':
        direction.moveToNext()
    separator_crumble = direction.crumble(direction.col)

    direction.moveToNext()

    stop2 = findOneOf(direction.closingBrackets+[','],direction)

    direction.col = direction.prev(stop2)
    if direction.current() == ' ':
        direction.col = direction.prev(direction.col)
    arg2_crumble = direction.crumble(direction.col)

    direction.join([prefix_crumble, arg2_crumble, separator_crumble, arg1_crumble]) 
    return direction.line, direction.col


def Swap(line, col):
    return SwapParms(RightwardDirection(line, col))

def SwapBackwards(line, col):
    return SwapParms(LeftwardDirection(line, col))
    
EOF

if a:directionName == 'backwards'
    python Swap = SwapBackwards 
endif

python << EOF
if __name__ == '__main__':
    import vim
    (row,col) = vim.current.window.cursor
    line = vim.current.buffer[row-1]
    try:
        (line, newCol) = Swap(line,col)
        vim.current.buffer[row-1] = line
        vim.current.window.cursor = (row, newCol)
    except Exception, e:
        print e
EOF
endfunction

noremap gb :call SwapParams("forwards")<cr>
map gs @='gb'<cr>

noremap gB :call SwapParams("backwards")<cr>
map gS @='gB'<cr>

"fun(arg2, arg4, arg3, arg1)
