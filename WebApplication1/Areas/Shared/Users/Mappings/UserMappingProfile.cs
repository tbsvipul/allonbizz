using AutoMapper;
using allonbiz.AdminAPI.Models.Entities;
using allonbiz.AdminAPI.DTOs.Users;
using allonbiz.AdminAPI.DTOs.Auth;

namespace allonbiz.AdminAPI.Mappings;

public class UserMappingProfile : Profile
{
    public UserMappingProfile()
    {
        CreateMap<AdminAccount, AdminProfileDto>();
    }
}
