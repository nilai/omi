import { X, Plus } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { useState, useEffect, useRef } from 'react';
import { CreateProjectModal } from './CreateProjectModal';

interface Project {
  id: string;
  name: string;
  isLinked: boolean;
}

interface ManageProjectsModalProps {
  isOpen: boolean;
  onClose: () => void;
  projects: Project[];
  onSave: (selectedProjectIds: string[]) => void;
  onCreateProject: (name: string) => { id: string; name: string };
}

export function ManageProjectsModal({
  isOpen,
  onClose,
  projects,
  onSave,
  onCreateProject,
}: ManageProjectsModalProps) {
  const [selectedProjects, setSelectedProjects] = useState<Set<string>>(
    new Set(projects.filter(p => p.isLinked).map(p => p.id))
  );
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [localProjects, setLocalProjects] = useState<Project[]>(projects);
  
  // Store initial state when modal opens
  const initialSelectedProjects = useRef<Set<string>>(new Set());
  
  // Update local projects and initial state when modal opens or projects prop changes
  useEffect(() => {
    if (isOpen) {
      setLocalProjects(projects);
      initialSelectedProjects.current = new Set(projects.filter(p => p.isLinked).map(p => p.id));
      setSelectedProjects(new Set(initialSelectedProjects.current));
    }
  }, [isOpen, projects]);

  const toggleProject = (projectId: string) => {
    setSelectedProjects(prev => {
      const next = new Set(prev);
      if (next.has(projectId)) {
        next.delete(projectId);
      } else {
        next.add(projectId);
      }
      return next;
    });
  };

  const handleSave = () => {
    onSave(Array.from(selectedProjects));
    onClose();
  };
  
  const handleCancel = () => {
    // Restore initial state
    setSelectedProjects(new Set(initialSelectedProjects.current));
    onClose();
  };

  const handleCreateProject = () => {
    setIsCreateModalOpen(true);
  };

  if (!isOpen) return null;

  // Separate projects into added and available
  const addedProjects = localProjects.filter(p => selectedProjects.has(p.id));
  const availableProjects = localProjects.filter(p => !selectedProjects.has(p.id));

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleCancel}
            className="fixed inset-0 bg-black/40 z-50"
          />

          {/* Bottom Sheet */}
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 30, stiffness: 300 }}
            className="fixed bottom-0 left-0 right-0 bg-[#f2f2f7] rounded-t-3xl z-50 max-h-[85vh] overflow-y-auto"
          >
            {/* Handle */}
            <div className="flex justify-center pt-3 pb-2">
              <div className="w-10 h-1 bg-[#c7c7cc] rounded-full" />
            </div>

            {/* Header */}
            <div className="flex items-center justify-between px-5 pt-2 pb-4">
              <h2 className="text-[20px] font-semibold text-[#1c1c1e]">
                Manage Projects
              </h2>
              <button
                onClick={handleCancel}
                className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-[#e5e5ea] active:opacity-60 transition-all"
              >
                <X className="w-5 h-5 text-[#1c1c1e]" strokeWidth={2.5} />
              </button>
            </div>

            {/* Content */}
            <div className="px-5 pb-6">
              {localProjects.length === 0 ? (
                // Empty State
                <>
                  <div className="flex flex-col items-center justify-center py-12 text-center">
                    <div className="w-16 h-16 bg-[#e5e5ea] rounded-full flex items-center justify-center mb-4">
                      <svg className="w-8 h-8 text-[#8e8e93]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                      </svg>
                    </div>
                    <p className="text-[17px] font-medium text-[#1c1c1e] mb-1">
                      No projects yet
                    </p>
                    <p className="text-[15px] text-[#8e8e93]">
                      Create a project to get started
                    </p>
                  </div>

                  {/* Separator */}
                  <div className="border-t border-[#c6c6c8] my-4" />

                  {/* Create New Project */}
                  <button
                    onClick={handleCreateProject}
                    className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-white active:opacity-60 transition-opacity"
                  >
                    <Plus className="w-5 h-5 text-[#007aff]" strokeWidth={2.5} />
                    <span className="text-[17px] font-medium text-[#007aff]">
                      Create new Project
                    </span>
                  </button>
                </>
              ) : (
                <>
                  {/* Description */}
                  <p className="text-[15px] text-[#8e8e93] mb-4 text-center">
                    This memory belongs to {selectedProjects.size} {selectedProjects.size === 1 ? 'project' : 'projects'}
                  </p>

                  {/* Separator */}
                  <div className="border-t border-[#c6c6c8] mb-4" />

                  {/* Added to projects */}
                  {addedProjects.length > 0 && (
                    <>
                      <div className="mb-3">
                        <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-3">
                          Added to projects
                        </h3>
                        <div className="space-y-0">
                          {addedProjects.map(project => (
                            <button
                              key={project.id}
                              onClick={() => toggleProject(project.id)}
                              className="w-full flex items-center gap-3 py-3 active:opacity-60 transition-opacity"
                            >
                              {/* Checkmark */}
                              <div className="w-6 h-6 rounded-full bg-[#34c759] flex items-center justify-center flex-shrink-0">
                                <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                                  <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                                </svg>
                              </div>
                              
                              {/* Project Name */}
                              <span className="text-[17px] text-[#1c1c1e] text-left flex-1">
                                {project.name}
                              </span>
                            </button>
                          ))}
                        </div>
                      </div>

                      {/* Separator */}
                      <div className="border-t border-[#c6c6c8] my-4" />
                    </>
                  )}

                  {/* Available projects */}
                  {availableProjects.length > 0 && (
                    <>
                      <div className="mb-3">
                        <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-3">
                          Available projects
                        </h3>
                        <div className="space-y-0">
                          {availableProjects.map(project => (
                            <button
                              key={project.id}
                              onClick={() => toggleProject(project.id)}
                              className="w-full flex items-center gap-3 py-3 active:opacity-60 transition-opacity"
                            >
                              {/* Empty Circle */}
                              <div className="w-6 h-6 rounded-full border-2 border-[#c6c6c8] flex items-center justify-center flex-shrink-0">
                              </div>
                              
                              {/* Project Name */}
                              <span className="text-[17px] text-[#1c1c1e] text-left flex-1">
                                {project.name}
                              </span>
                            </button>
                          ))}
                        </div>
                      </div>

                      {/* Separator */}
                      <div className="border-t border-[#c6c6c8] my-4" />
                    </>
                  )}

                  {/* Create New Project */}
                  <button
                    onClick={handleCreateProject}
                    className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-white active:opacity-60 transition-opacity mb-4"
                  >
                    <Plus className="w-5 h-5 text-[#007aff]" strokeWidth={2.5} />
                    <span className="text-[17px] font-medium text-[#007aff]">
                      Create new Project
                    </span>
                  </button>

                  {/* Separator */}
                  <div className="border-t border-[#c6c6c8] mb-4" />
                </>
              )}

              {/* Footer Buttons */}
              <div className="flex gap-3">
                <button
                  onClick={handleCancel}
                  className="flex-1 py-3 rounded-xl bg-white text-[#1c1c1e] text-[17px] font-semibold active:opacity-60 transition-opacity"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSave}
                  className="flex-1 py-3 rounded-xl bg-[#007aff] text-white text-[17px] font-semibold active:opacity-60 transition-opacity"
                >
                  Save
                </button>
              </div>
            </div>
          </motion.div>

          {/* Create Project Modal */}
          <CreateProjectModal
            isOpen={isCreateModalOpen}
            onClose={() => setIsCreateModalOpen(false)}
            onCreate={(name) => {
              // Call parent's onCreateProject and get the new project info
              const newProject = onCreateProject(name);
              
              // Add the new project to local state
              const newProjectWithLinked: Project = {
                id: newProject.id,
                name: newProject.name,
                isLinked: false
              };
              
              setLocalProjects(prev => [...prev, newProjectWithLinked]);
              
              // Automatically select the new project
              setSelectedProjects(prev => {
                const next = new Set(prev);
                next.add(newProject.id);
                return next;
              });
              
              // Close the create modal
              setIsCreateModalOpen(false);
            }}
          />
        </>
      )}
    </AnimatePresence>
  );
}