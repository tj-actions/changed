import {Pattern} from '@actions/glob/lib/internal-pattern'
import * as path from 'path'

import {SHAResult} from './commitSha'
import {Inputs} from './inputs'
import {
  getDirnameMaxDepth,
  getSubmodulePath,
  gitDiff,
  gitRenamedFiles,
  gitSubmoduleDiffSHA,
  jsonOutput
} from './utils'

export const getRenamedFiles = async ({
  inputs,
  workingDirectory,
  hasSubmodule,
  shaResult
}: {
  inputs: Inputs
  workingDirectory: string
  hasSubmodule: boolean
  shaResult: SHAResult
}): Promise<string> => {
  let renamedFiles = await gitRenamedFiles({
    cwd: workingDirectory,
    sha1: shaResult.previousSha,
    sha2: shaResult.currentSha,
    diff: shaResult.diff,
    oldNewSeparator: inputs.oldNewSeparator
  })

  if (hasSubmodule) {
    for (const submodulePath of await getSubmodulePath({
      cwd: workingDirectory
    })) {
      const submoduleShaResult = await gitSubmoduleDiffSHA({
        cwd: workingDirectory,
        parentSha1: shaResult.previousSha,
        parentSha2: shaResult.currentSha,
        submodulePath,
        diff: shaResult.diff
      })

      const submoduleWorkingDirectory = path.join(
        workingDirectory,
        submodulePath
      )

      if (submoduleShaResult.currentSha && submoduleShaResult.previousSha) {
        const submoduleRenamedFiles = await gitRenamedFiles({
          cwd: submoduleWorkingDirectory,
          sha1: submoduleShaResult.previousSha,
          sha2: submoduleShaResult.currentSha,
          diff: shaResult.diff,
          oldNewSeparator: inputs.oldNewSeparator,
          isSubmodule: true
        })
        renamedFiles.push(...submoduleRenamedFiles)
      }
    }
  }

  if (inputs.dirNames) {
    renamedFiles = renamedFiles.map(renamedFile =>
      getDirnameMaxDepth({
        pathStr: renamedFile,
        dirNamesMaxDepth: inputs.dirNamesMaxDepth,
        excludeRoot: inputs.dirNamesExcludeRoot
      })
    )
  }

  if (inputs.json) {
    return jsonOutput({value: renamedFiles, escape: inputs.escapeJson})
  }

  return renamedFiles.join(inputs.oldNewFilesSeparator)
}

export const getDiffFiles = async ({
  inputs,
  workingDirectory,
  hasSubmodule,
  shaResult,
  diffFilter,
  filePatterns = []
}: {
  inputs: Inputs
  workingDirectory: string
  hasSubmodule: boolean
  shaResult: SHAResult
  diffFilter: string
  filePatterns?: Pattern[]
}): Promise<string> => {
  let files = await gitDiff({
    cwd: workingDirectory,
    sha1: shaResult.previousSha,
    sha2: shaResult.currentSha,
    diff: shaResult.diff,
    diffFilter,
    filePatterns
  })

  if (hasSubmodule) {
    for (const submodulePath of await getSubmodulePath({
      cwd: workingDirectory
    })) {
      const submoduleShaResult = await gitSubmoduleDiffSHA({
        cwd: workingDirectory,
        parentSha1: shaResult.previousSha,
        parentSha2: shaResult.currentSha,
        submodulePath,
        diff: shaResult.diff
      })

      const submoduleWorkingDirectory = path.join(
        workingDirectory,
        submodulePath
      )

      if (submoduleShaResult.currentSha && submoduleShaResult.previousSha) {
        const submoduleFiles = await gitDiff({
          cwd: submoduleWorkingDirectory,
          sha1: submoduleShaResult.previousSha,
          sha2: submoduleShaResult.currentSha,
          diff: shaResult.diff,
          diffFilter,
          isSubmodule: true,
          filePatterns
        })
        files.push(...submoduleFiles)
      }
    }
  }

  if (inputs.dirNames) {
    files = files.map(file =>
      getDirnameMaxDepth({
        pathStr: file,
        dirNamesMaxDepth: inputs.dirNamesMaxDepth,
        excludeRoot: inputs.dirNamesExcludeRoot
      })
    )
  }

  if (inputs.json) {
    return jsonOutput({value: files, escape: inputs.escapeJson})
  }

  return files.join(inputs.separator)
}
